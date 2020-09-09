# Copyright 2020 Google LLC
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

'''Cloud Function module to export data for a given day.

This module is designed to be plugged in a Cloud Function, attached to Cloud
Scheduler trigger to create a Cloud Asset Inventory Export to BigQuery.

'''

import base64
import datetime
import json
import logging
import os
import warnings

import click

from google.api_core.exceptions import GoogleAPIError
from google.cloud import asset_v1

import googleapiclient.discovery
import googleapiclient.errors

def _configure_logging(verbose=True):
  """Basic logging configuration.
  Args:
    verbose: enable verbose logging
  """
  level = logging.DEBUG if verbose else logging.INFO
  logging.basicConfig(level=level)
  warnings.filterwarnings('ignore', r'.*end user credentials.*', UserWarning)

@click.command()
@click.option('--organization', required=True,
              help='Organization ID')
@click.option('--bq-project', required=True,
              help='Bigquery project to use.')
@click.option('--bq-dataset', required=True,
              help='Bigquery dataset to use.')
@click.option('--bq-table', required=True,
              help='Bigquery table name to use.')
@click.option('--read-time', required=True,
              help='Day to take an asset snapshot in the format \'YYYYMMDD\'. \
              If not specified run for the current day. Export will run for \
              the midnight of the specified day.')
@click.option('--verbose', is_flag=True, help='Verbose output')
def main_cli(organization=None, bq_project=None, bq_dataset=None, bq_table=None, read_time=None, verbose=False):
  """Trigger Cloud Asset inventory export to Bigquery. Data will
  be stored in the dataset specified on a dated table with the name
  specified.
  """
  try:
    _main(organization, bq_project, bq_dataset, bq_table)
  except RuntimeError:
    logging.exception('exception raised')


def main(event, context):
  """Cloud Function entry point."""
  try:
    _main(**event)
  # uncomment once https://issuetracker.google.com/issues/155215191 is fixed
  # except RuntimeError:
  #  raise
  except Exception:
    logging.exception('exception in cloud function entry point')


def _main(organization=None, bq_project=None, bq_dataset=None, bq_table=None, read_time=None, verbose=False):
  """Module entry point used by cli and cloud function wrappers."""

  if not read_time:
    read_time = datetime.date.today().strftime("%Y%m%d")

  client = asset_v1.AssetServiceClient()
  parent = "organizations/%s" % organization
  content_type = asset_v1.ContentType.RESOURCE
  output_config = asset_v1.OutputConfig()
  output_config.bigquery_destination.dataset = "projects/%s/datasets/%s" % (bq_project, bq_dataset)
  output_config.bigquery_destination.table = "%s_%s" % (bq_table, read_time)
  output_config.bigquery_destination.force = True
  response = client.export_assets(
    request={
      "parent": parent,
      "read_time": datetime.datetime.strptime(read_time, '%Y%m%d'),
      "content_type": content_type,
      "output_config": output_config
    }
  )


if __name__ == '__main__':
  main_cli()
