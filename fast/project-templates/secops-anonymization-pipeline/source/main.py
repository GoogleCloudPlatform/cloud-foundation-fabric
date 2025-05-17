# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import binascii
import json
import os
import click
import logging
import google.cloud.logging
from jinja2 import Template
from shared import utils
from google.cloud import dlp_v2
from google.cloud import storage
from datetime import date, timedelta, datetime
from secops import SecOpsClient

client = google.cloud.logging.Client()
client.setup_logging()

LOGGER = logging.getLogger('secops')
logging.basicConfig(
    level=logging.DEBUG if os.environ.get('DEBUG') else logging.INFO,
    format='[%(levelname)-8s] - %(asctime)s - %(message)s')
logging.root.setLevel(logging.DEBUG)

SECOPS_REGION = os.environ.get("SECOPS_REGION")
GCP_PROJECT_ID = os.environ.get("GCP_PROJECT")
SECOPS_EXPORT_BUCKET = os.environ.get("SECOPS_EXPORT_BUCKET")
SECOPS_OUTPUT_BUCKET = os.environ.get("SECOPS_OUTPUT_BUCKET")
SECOPS_SOURCE_PROJECT = os.environ.get("SECOPS_SOURCE_PROJECT")
SECOPS_TARGET_PROJECT = os.environ.get("SECOPS_TARGET_PROJECT")
SECOPS_SOURCE_CUSTOMER_ID = os.environ.get("SECOPS_SOURCE_CUSTOMER_ID")
SECOPS_TARGET_CUSTOMER_ID = os.environ.get("SECOPS_TARGET_CUSTOMER_ID")
SECOPS_TARGET_FORWARDER_ID = os.environ.get("SECOPS_TARGET_FORWARDER_ID")
SKIP_ANONYMIZATION = False if (os.environ.get(
    "SKIP_ANONYMIZATION", "false").lower() == "false") else True
DLP_DEIDENTIFY_TEMPLATE_ID = os.environ.get("DLP_DEIDENTIFY_TEMPLATE_ID")
DLP_INSPECT_TEMPLATE_ID = os.environ.get("DLP_INSPECT_TEMPLATE_ID")
DLP_REGION = os.environ.get("DLP_REGION")


def import_logs(export_date):
  client = SecOpsClient()
  chronicle = client.chronicle(customer_id=SECOPS_TARGET_CUSTOMER_ID,
                               project_id=SECOPS_TARGET_PROJECT,
                               region=SECOPS_REGION)

  storage_client = storage.Client()
  BUCKET = SECOPS_OUTPUT_BUCKET if not SKIP_ANONYMIZATION else SECOPS_EXPORT_BUCKET
  bucket = storage_client.bucket(BUCKET)
  export_ids = utils.get_secops_export_folders_for_date(BUCKET, export_date)

  for export_id in export_ids:
    for folder in utils.list_anonymized_folders(BUCKET, export_id):
      log_type = folder.split("-")[0]

      for log_file in utils.list_log_files(BUCKET, f"{export_id}/{folder}"):
        try:
          blob = bucket.blob(log_file)  # Directly get the blob object
          with blob.open("r") as f:
            logs = []
            for line in f:
              logs.append(line.rstrip('\n'))
              if len(logs) == 1000:
                response = chronicle.ingest_log(
                    log_message=logs, log_type=log_type,
                    forwarder_id=SECOPS_TARGET_FORWARDER_ID)
                LOGGER.debug(response)
                logs = []

            # Send any remaining entries
            if len(logs) > 0:
              response = chronicle.ingest_log(
                  log_message=logs, log_type=log_type,
                  forwarder_id=SECOPS_TARGET_FORWARDER_ID)
              LOGGER.debug(response)
        except Exception as e:
          LOGGER.error(f"Error during log ingestion': {e}")
          raise SystemExit(f'Error during log ingestion: {e}')

    # delete both export and anonymized buckets after ingesting logs
    utils.delete_folder(BUCKET, export_id)
    if not SKIP_ANONYMIZATION:
      utils.delete_folder(SECOPS_EXPORT_BUCKET, export_id)

  LOGGER.info("Finished importing data.")


def trigger_export(export_date: str, export_start_datetime: str,
                   export_end_datetime: str, log_types: str):
  """
    Trigger secops export using Data Export API for a specific date
    :param secops_source_sa_key_secret_path:
    :param secops_export_bucket:
    :param secops_target_project_id:
    :param log_types:
    :param export_end_datetime:
    :param export_start_datetime:
    :param export_date:
    :param date: datetime (as string) with DD-MM-YYYY format
    :return:
  """

  client = SecOpsClient()
  chronicle = client.chronicle(customer_id=SECOPS_SOURCE_CUSTOMER_ID,
                               project_id=SECOPS_SOURCE_PROJECT,
                               region=SECOPS_REGION)

  export_ids = []

  if export_start_datetime and export_end_datetime:
    start_time, end_time = datetime.strptime(
        export_start_datetime,
        "%Y-%m-%dT%H:%M:%SZ"), datetime.strptime(export_end_datetime,
                                                 "%Y-%m-%dT%H:%M:%SZ")
  else:
    start_time, end_time = utils.format_date_time_range(date_input=export_date)
  gcs_bucket = f"projects/{GCP_PROJECT_ID}/buckets/{SECOPS_EXPORT_BUCKET}"

  try:
    if log_types is None or log_types == "":
      export_response = chronicle.create_data_export(start_time=start_time,
                                                     end_time=end_time,
                                                     gcs_bucket=gcs_bucket,
                                                     export_all_logs=True)
      LOGGER.info(export_response)
      export_id = export_response["dataExportStatus"]["name"].split("/")[-1]
      export_ids.append(export_id)
      LOGGER.info(f"Triggered export with ID: {export_id}")
    else:
      for log_type in log_types.split(","):
        export_response = chronicle.create_data_export(start_time=start_time,
                                                       end_time=end_time,
                                                       gcs_bucket=gcs_bucket,
                                                       log_type=log_type)
        export_id = export_response["dataExportStatus"]["name"].split("/")[-1]
        export_ids.append(export_id)
        LOGGER.info(f"Triggered export with ID: {export_id}")
  except Exception as e:
    LOGGER.error(f"Error during export': {e}")
    raise SystemExit(f'Error during secops export: {e}')

  return export_ids


def anonymize_data(export_date):
  """
  Trigger DLP Job and setup secops feeds to ingest data from output bucket.
  :param export_date: date for which data should be anonymized
  :return:
  """

  client = SecOpsClient()
  chronicle = client.chronicle(customer_id=SECOPS_SOURCE_CUSTOMER_ID,
                               project_id=SECOPS_SOURCE_PROJECT,
                               region=SECOPS_REGION)
  export_ids = utils.get_secops_export_folders_for_date(SECOPS_EXPORT_BUCKET,
                                                        export_date=export_date)

  export_finished = True
  for export_id in export_ids:
    export = chronicle.get_data_export(data_export_id=export_id)
    LOGGER.info(f"Export response: {export}.")
    if "dataExportStatus" in export and export["dataExportStatus"][
        "stage"] == "FINISHED_SUCCESS":
      export_state = export["dataExportStatus"]["stage"]
      LOGGER.info(f"Export status: {export_state}.")
    else:
      export_finished = False
      break

  if export_finished:
    for export_id in export_ids:
      utils.split_and_rename_csv_to_log_files(SECOPS_EXPORT_BUCKET, export_id)

      with open("dlp_job_template.json.tpl", "r") as template_file:
        content = template_file.read()
        template = Template(content)
        rendered_str = template.render({
            "export_bucket": SECOPS_EXPORT_BUCKET,
            "output_bucket": SECOPS_OUTPUT_BUCKET,
            "deidentify_template_id": DLP_DEIDENTIFY_TEMPLATE_ID,
            "inspect_template_id": DLP_INSPECT_TEMPLATE_ID,
            "export_id": export_id
        })
        LOGGER.info(f"Filled template: {rendered_str}")
        dlp_job = json.loads(rendered_str)
        LOGGER.info(dlp_job)

        job_request = {
            "parent": f"projects/{GCP_PROJECT_ID}/locations/{DLP_REGION}",
            "inspect_job": dlp_job
        }

        try:
          dlp_client = dlp_v2.DlpServiceClient(
              client_options={'quota_project_id': GCP_PROJECT_ID})
          response = dlp_client.create_dlp_job(request=job_request)
          LOGGER.info(response)
        except Exception as e:
          LOGGER.error(f"Error during export': {e}")
          raise SystemExit(f'Error during secops export: {e}')

  else:
    LOGGER.error("Export is not finished yet, please try again later.")

  LOGGER.info("Triggered all DLP jobs successfully.")


def main(request):
  """
    Entry point for Cloud Function triggered by HTTP request.
    :param request: payload of HTTP request triggering cloud function
    :return:
    """
  debug = os.environ.get('DEBUG')
  logging.basicConfig(level=logging.INFO)
  LOGGER.info('processing http payload')
  try:
    payload = json.loads(request.data)
  except (binascii.Error, json.JSONDecodeError) as e:
    raise SystemExit(f'Invalid payload: {e.args[0]}.')
  if "EXPORT_DATE" in payload:
    export_date = payload.get('EXPORT_DATE')
  else:
    export_date = date.today().strftime("%Y-%m-%d")
  action = payload.get('ACTION')
  export_start_datetime = payload.get('EXPORT_START_DATETIME', None)
  export_end_datetime = payload.get('EXPORT_END_DATETIME', None)
  log_types = payload.get('LOG_TYPES', None)

  match action:
    case "TRIGGER-EXPORT":
      trigger_export(export_date=export_date,
                     export_start_datetime=export_start_datetime,
                     export_end_datetime=export_end_datetime,
                     log_types=log_types)
    case "ANONYMIZE-DATA":
      anonymize_data(export_date=export_date)
    case "IMPORT-DATA":
      import_logs(export_date=export_date)
    case _:
      return "Action must be either 'TRIGGER-EXPORT', 'ANONYMIZE-DATA' or 'IMPORT-DATA'"

  return "Success."


@click.command()
@click.option('--export-date', '-d', required=False, type=str,
              help='Date for secops export and anonymization.')
@click.option('--export-start-datetime', '-d', required=False, type=str,
              help='Start datetime for secops export and anonymization.')
@click.option('--export-end-datetime', '-d', required=False, type=str,
              help='End datetime for secops export and anonymization.')
@click.option('--log-type', type=str, multiple=True)
@click.option(
    '--action',
    type=click.Choice(['TRIGGER-EXPORT', 'ANONYMIZE-DATA',
                       'IMPORT-DATA']), required=True)
@click.option('--debug', is_flag=True, default=False,
              help='Turn on debug logging.')
def main_cli(export_date, export_start_datetime, export_end_datetime,
             log_type: list, action: str, debug=False):
  """
    CLI entry point.
    :param date: date for secops export and anonymization
    :param debug: whether to enable debug logs
    :return:
    """
  logging.basicConfig(level=logging.INFO if not debug else logging.DEBUG)
  match action:
    case "TRIGGER-EXPORT":
      trigger_export(export_date=export_date,
                     export_start_datetime=export_start_datetime,
                     export_end_datetime=export_end_datetime,
                     log_types=','.join(log_type))
    case "ANONYMIZE-DATA":
      anonymize_data(export_date=export_date)
    case "IMPORT-DATA":
      import_logs(export_date=export_date)
    case _:
      return "Action must be either 'TRIGGER-EXPORT', 'ANONYMIZE-DATA' or 'IMPORT-DATA'"

  return "Success."


if __name__ == '__main__':
  main_cli()
