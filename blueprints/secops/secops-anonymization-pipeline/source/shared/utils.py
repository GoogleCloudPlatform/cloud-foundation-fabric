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

import os
import logging
import math
import csv
from google.cloud import secretmanager, storage, exceptions
from datetime import datetime, timedelta, timezone, time

LOGGER = logging.getLogger('secops')
"""Utility functions required for ingestion scripts."""
MAX_FILE_SIZE = 61440000  # Max size supported by DLP


def get_value_from_secret_manager(resource_path: str) -> str:
  """Retrieve the value of the secret from the Google Cloud Secret Manager.

    Args:
      resource_path (str): Path of the secret with version included. Ex.:
        "projects/<project_id>/secrets/<secret_name>/versions/1",
        "projects/<project_id>/secrets/<secret_name>/versions/latest"

    Returns:
      str: Payload for secret.
    """
  client = secretmanager.SecretManagerServiceClient()
  response = client.access_secret_version(name=resource_path)
  return response.payload.data.decode("UTF-8")


def format_date_time_range(date_input):
  """
    Creates datetime objects for the beginning and end of the input date
    and formats them.

    Args:
        date_input: A string representing the date (e.g., "2024-06-10").

    Returns:
        A tuple containing two formatted strings:
            - Start of day: "YYYY-MM-DDTHH:MM:SSZ"
            - End of day:   "YYYY-MM-DDTHH:MM:SSZ"
    """
  date_obj = datetime.strptime(date_input, "%Y-%m-%d")

  start_of_day = datetime.combine(date_obj.date(), time.min,
                                  tzinfo=timezone.utc)
  end_of_day = start_of_day + timedelta(days=1, seconds=-1)

  # Format both datetime objects
  formatted_start = start_of_day.strftime("%Y-%m-%dT%H:%M:%SZ")
  formatted_end = end_of_day.strftime("%Y-%m-%dT%H:%M:%SZ")

  return formatted_start, formatted_end


def list_anonymized_folders(bucket_name, folder_name):
  """Lists all folders (prefixes) within a specified folder in a GCS bucket.

      Args:
          bucket_name: Name of the GCS bucket.
          folder_name: Name of the folder (prefix) to search within.

      Returns:
          A list of folder names (prefixes) found.
      """
  folders = []
  storage_client = storage.Client()
  for blob in storage_client.list_blobs(bucket_name, prefix=f"{folder_name}/"):
    folder_name = blob.name.split('/')[1]
    if not folder_name in folders:
      folders.append(folder_name)

  return folders


def delete_folder(bucket_name, folder_name):
  """Deletes a folder from a Google Cloud Storage bucket.

    Args:
      bucket_name: The name of the bucket.
      folder_name: The name of the folder to delete.
    """

  storage_client = storage.Client()
  bucket = storage_client.bucket(bucket_name)

  # List all blobs with the given prefix (folder name)
  blobs = list(bucket.list_blobs(prefix=folder_name))

  # Delete the blobs in parallel
  bucket.delete_blobs(blobs)

  print(f"Folder {folder_name} deleted from bucket {bucket_name}")


def list_log_files(bucket_name, folder_name):
  """Lists all folders (prefixes) within a specified folder in a GCS bucket.

    Args:
        bucket_name: Name of the GCS bucket.
        folder_name: Name of the folder (prefix) to search within.

    Returns:
        A list of folder names (prefixes) found.
    """

  storage_client = storage.Client()
  csv_files = []
  for blob in storage_client.list_blobs(bucket_name, prefix=f"{folder_name}/"):
    if blob.name.endswith(".log") or blob.name.endswith(".csv"):
      csv_files.append(blob.name)

  return csv_files


def split_csv(bucket_name, blob_name, file_size):
  """Splits a CSV file into smaller chunks and uploads them back to the bucket.

    Args:
      bucket_name: The name of the GCS bucket.
      blob_name: The name of the CSV blob in the bucket.
      max_file_size: The maximum size of each chunk in bytes.
    """
  storage_client = storage.Client()
  bucket = storage_client.bucket(bucket_name)
  blob = bucket.blob(blob_name)

  # Download the blob to a local file
  temp_file = '/tmp/temp.csv'
  blob.download_to_filename(temp_file)

  file = open(temp_file, encoding="utf8")
  numline = sum(1 for row in csv.reader(file))

  # Read the CSV file in chunks
  chunk_number = math.ceil(numline * MAX_FILE_SIZE / file_size)
  index = 0
  lines = []
  with open(temp_file, 'r', encoding="utf8") as f_in:
    reader = csv.reader(f_in, delimiter='\n')
    for line in reader:
      lines.append(line[0] + "\n")
      if len(lines) == chunk_number:
        chunk_filename = f'{blob_name.split(".")[0]}_{index}.log'
        chunk_path = f'/tmp/temp-{index}.csv'
        with open(chunk_path, 'w') as fout:
          fout.writelines(lines)
        chunk_blob = bucket.blob(f'{chunk_filename}')
        chunk_blob.upload_from_filename(chunk_path)
        print(f'Uploaded {chunk_filename} to {bucket_name}')
        os.remove(chunk_path)  # Remove the local chunk file
        index += 1
        lines = []

    chunk_filename = f'{blob_name.split(".")[0]}_{index}.log'
    chunk_path = f'/tmp/temp-{index}.csv'
    with open(chunk_path, 'w') as fout:
      fout.writelines(lines)
    chunk_blob = bucket.blob(f'{chunk_filename}')
    chunk_blob.upload_from_filename(chunk_path)
    print(f'Uploaded {chunk_filename} to {bucket_name}')
    os.remove(chunk_path)  # Remove the local chunk file
    index += 1
    lines = []

  # Remove the temporary file
  os.remove(temp_file)

  # remove old log file
  blob = bucket.blob(blob_name)
  blob.delete()


def split_and_rename_csv_to_log_files(bucket_name, folder_name):
  """Renames all .csv files to .log files within a GCS bucket folder (and subfolders).

    Args:
        bucket_name (str): Name of the GCS bucket.
        folder_prefix (str): Prefix of the folder within the bucket to process.
    """

  storage_client = storage.Client()
  bucket = storage_client.bucket(bucket_name)

  blobs = storage_client.list_blobs(bucket, prefix=f"{folder_name}/")
  for blob in blobs:
    if blob.name.endswith(".csv") and blob.size >= MAX_FILE_SIZE:
      split_csv(bucket_name, blob.name, blob.size)
    elif blob.name.endswith(".csv"):
      new_name = blob.name.replace(".csv", ".log")
      bucket.rename_blob(blob, new_name)


def get_secops_export_folders_for_date(bucket_name, export_date):
  storage_client = storage.Client()
  export_ids = []

  for blob in storage_client.list_blobs(bucket_name):
    if blob.time_created.strftime(
        "%Y-%m-%d") == export_date and blob.name.split(
            '/')[0] not in export_ids:
      export_ids.append(blob.name.split('/')[0])

  return export_ids
