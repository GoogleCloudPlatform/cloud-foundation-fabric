# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import google.auth
import logging
import requests
import os
from . import utils
from google.auth.transport.requests import AuthorizedSession
"""SecOps utility functions."""

LOGGER = logging.getLogger("secops")
SECOPS_REGION = os.environ.get("SECOPS_REGION")
SECOPS_EXPORT_BUCKET = os.environ.get("SECOPS_EXPORT_BUCKET")
SECOPS_OUTPUT_BUCKET = os.environ.get("SECOPS_OUTPUT_BUCKET")


class SecOpsUtils:

  def __init__(self, credentials=None):
    self.BACKSTORY_API_URL = f"https://{SECOPS_REGION}-backstory.googleapis.com/v1/tools/dataexport"
    self.INGESTION_API_URL = F"https://{SECOPS_REGION}-malachiteingestion-pa.googleapis.com"
    self.HTTP = AuthorizedSession(credentials=credentials if credentials
                                  is not None else google.auth.default()[0])

  def create_data_export(self, project, export_date, export_start_datetime,
                         export_end_datetime, log_type: str = None):
    """
        Trigger Chronicle data export for the given date and log types.

        :param export_start_datetime:
        :param export_date:
        :param project:
        :param session: auth session for API call
        :param date: date for which data will be exported
        :return: Chronicle Data export response.
        """
    if export_start_datetime and export_end_datetime:
      start_time, end_time = export_start_datetime, export_end_datetime
    else:
      start_time, end_time = utils.format_date_time_range(
          date_input=export_date)
    gcs_bucket = f"projects/{project}/buckets/{SECOPS_EXPORT_BUCKET}"

    body = {
        "startTime": start_time,
        "endTime": end_time,
        "logType": "ALL_TYPES" if log_type is None else log_type,
        "gcsBucket": gcs_bucket,
    }

    response = self.HTTP.post(self.BACKSTORY_API_URL, json=body)
    response.raise_for_status()
    print(f"Data export created successfully.")
    return response.json()

  def get_data_export(self, export_id: str) -> str:
    """
        Get Chronicle data export information.

        :param export_id: ID of Chronicle export to get information from
        :return: Data Export status
        :raises requests.exceptions.HTTPError: If the API request fails.
        """
    try:
      response = self.HTTP.get(f"{self.BACKSTORY_API_URL}/{export_id}")
      response.raise_for_status(
      )  # Raise HTTPError for bad responses (4xx or 5xx)
      print(
          f"Data export for '{export_id}' retrieved, content is {response.json()}"
      )
      return response.json()
    except requests.exceptions.HTTPError as e:
      print(f"Error fetching data export '{export_id}': {e}")
      # You can choose to handle the error in a more specific way here,
      # like retrying the request, logging the error, or raising a custom exception.
      raise  # Re-raise the exception to be handled by the caller

  def list_log_types(self, date):
    start_date, end_date = utils.format_date_time_range(date)
    params = {
        "startTime": start_date,
        "endTime": end_date,
    }
    response = self.HTTP.get(f"{self.BACKSTORY_API_URL}/listavailablelogtypes")
    response.raise_for_status()
    if response.status_code == 200:
      logging.info(f"Log types for date: {date} is {response.json()}")
      log_types = response.json()["availableLogTypes"]
    else:
      error_message = response.json().get("error",
                                          {}).get("message", "Unknown error")
      status_code = response.status_code
      logging.error(
          f"Error listing log types on {date} (Status code: {status_code}) Error message: {error_message}"
      )
      raise Exception("Error while listing log types.")

    return log_types
