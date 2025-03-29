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
import base64
import uuid
from datetime import datetime
from typing import Optional, Any, List, Dict

import google.auth
import logging
import requests
import os
from . import utils
from google.auth.transport.requests import AuthorizedSession
from google.auth.transport import requests as google_auth_requests
from google.auth.credentials import Credentials
from google.oauth2 import service_account
import google.auth
import google.auth.transport.requests

"""SecOps utility functions."""

LOGGER = logging.getLogger("secops")
SECOPS_REGION = os.environ.get("SECOPS_REGION")
SECOPS_EXPORT_BUCKET = os.environ.get("SECOPS_EXPORT_BUCKET")
SECOPS_OUTPUT_BUCKET = os.environ.get("SECOPS_OUTPUT_BUCKET")



# Define default scopes needed for Chronicle API
CHRONICLE_SCOPES = [
  "https://www.googleapis.com/auth/cloud-platform"
]

class SecOpsAuth:
  """Handles authentication for the Google SecOps SDK."""

  def __init__(
          self,
          credentials: Optional[Credentials] = None,
          service_account_path: Optional[str] = None,
          service_account_info: Optional[Dict[str, Any]] = None,
          scopes: Optional[List[str]] = None
  ):
    """Initialize authentication for SecOps.

    Args:
        credentials: Optional pre-existing Google Auth credentials
        service_account_path: Optional path to service account JSON key file
        service_account_info: Optional service account JSON key data as dict
        scopes: Optional list of OAuth scopes to request
    """
    self.scopes = scopes or CHRONICLE_SCOPES
    self.credentials = self._get_credentials(
      credentials,
      service_account_path,
      service_account_info
    )
    self._session = None

  def _get_credentials(
          self,
          credentials: Optional[Credentials],
          service_account_path: Optional[str],
          service_account_info: Optional[Dict[str, Any]]
  ) -> Credentials:
    """Get credentials from various sources."""
    try:
      if credentials:
        return credentials.with_scopes(self.scopes)

      if service_account_info:
        return service_account.Credentials.from_service_account_info(
          service_account_info,
          scopes=self.scopes
        )

      if service_account_path:
        return service_account.Credentials.from_service_account_file(
          service_account_path,
          scopes=self.scopes
        )

      # Try to get default credentials
      credentials, project = google.auth.default(scopes=self.scopes)
      return credentials
    except Exception as e:
      raise Exception(f"Failed to get credentials: {str(e)}")

  @property
  def session(self):
    """Get an authorized session using the credentials.

    Returns:
        Authorized session for API requests
    """
    if self._session is None:
      self._session = google.auth.transport.requests.AuthorizedSession(
        self.credentials
      )
    return self._session


class ChronicleClient:
  """Client for the Chronicle API."""

  def __init__(
          self,
          project_id: str,
          customer_id: str,
          region: str = "us",
          auth: Optional[Any] = None,
          session: Optional[Any] = None,
          extra_scopes: Optional[List[str]] = None,
          credentials: Optional[Any] = None,
  ):
    """Initialize ChronicleClient.

    Args:
        project_id: Google Cloud project ID
        customer_id: Chronicle customer ID
        region: Chronicle region, typically "us" or "eu"
        auth: Authentication object
        session: Custom session object
        extra_scopes: Additional OAuth scopes
        credentials: Credentials object
    """
    self.project_id = project_id
    self.customer_id = customer_id
    self.region = region

    # Format the instance ID to match the expected format
    self.instance_id = f"projects/{project_id}/locations/{region}/instances/{customer_id}"

    # Set up the base URL
    self.base_url = f"https://{self.region}-chronicle.googleapis.com/v1alpha"

    # Create a session with authentication
    if session:
      self._session = session
    else:

      if auth is None:
        auth = SecOpsAuth(
          scopes=[
                   "https://www.googleapis.com/auth/cloud-platform",
                   "https://www.googleapis.com/auth/chronicle-backstory",
                 ] + (extra_scopes or []),
          credentials=credentials,
        )

      self._session = auth.session

  @property
  def session(self) -> google_auth_requests.AuthorizedSession:
    """Get an authenticated session.

    Returns:
        Authorized session for API requests
    """
    return self._session

  def create_data_export(self, project, export_date, export_start_datetime, export_end_datetime, log_type: str = None):
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

    # Construct the import URL
    url = f"{self.base_url}/{self.instance_id}/dataExports"

    # Generate a unique ID for this log entry
    log_id = str(uuid.uuid4())

    # Construct the request payload
    payload = {
      "name": log_id,
      "start_time": start_time,
      "end_time": end_time,
      "log_type": "" if log_type is None else f"projects/{self.project_id}/locations/{self.region}/instances/{self.customer_id}/logTypes/{log_type}",
      "gcs_bucket": gcs_bucket
      #"export_all_logs": "true" if log_type is None else "false"
    }
    print(f"Payload: {payload}")

    # Send the request
    response = self.session.post(url, json=payload)
    print(f"Data export created successfully.")
    return response.json()


  def get_data_export(self, name: str):
    """
        Trigger Chronicle data export for the given date and log types.

        :param name: name of data export request
        :return: Chronicle Data export response.
        """

    # Construct the import URL
    url = f"{self.base_url}/{self.instance_id}/dataExports/{name}"

    # Send the request
    response = self.session.get(url)
    print(f"Data export created successfully.")
    return response.json()

  def ingest_logs(
          self,
          log_type: str,
          logs: list,
          log_entry_time: Optional[datetime] = None,
          collection_time: Optional[datetime] = None,
          forwarder_id: Optional[str] = None,
          force_log_type: bool = False
  ) -> Dict[str, Any]:
    """Ingest a log into Chronicle.

    Args:
        self: ChronicleClient instance
        log_type: Chronicle log type (e.g., "OKTA", "WINDOWS", etc.)
        log_message: The raw log message to ingest
        log_entry_time: The time the log entry was created (defaults to current time)
        collection_time: The time the log was collected (defaults to current time)
        forwarder_id: ID of the forwarder to use (creates or uses default if None)
        force_log_type: Whether to force using the log type even if not in the valid list

    Returns:
        Dictionary containing the operation details for the ingestion

    Raises:
        ValueError: If the log type is invalid or timestamps are invalid
        APIError: If the API request fails
    """
    # Validate log type
    # if not is_valid_log_type(log_type) and not force_log_type:
    #   raise ValueError(f"Invalid log type: {log_type}. Use force_log_type=True to override.")

    # Get current time as default for log_entry_time and collection_time
    now = datetime.now()

    # If log_entry_time is not provided, use current time
    if log_entry_time is None:
      log_entry_time = now

    # If collection_time is not provided, use current time
    if collection_time is None:
      collection_time = now

    # Validate that collection_time is not before log_entry_time
    if collection_time < log_entry_time:
      raise ValueError("Collection time must be same or after log entry time")

    # Format timestamps for API
    log_entry_time_str = log_entry_time.strftime("%Y-%m-%dT%H:%M:%S.%fZ")
    collection_time_str = collection_time.strftime("%Y-%m-%dT%H:%M:%S.%fZ")

    # If forwarder_id is not provided, get or create default forwarder
    # if forwarder_id is None:
    #   forwarder = get_or_create_forwarder(client)
    #   forwarder_id = extract_forwarder_id(forwarder["name"])

    # Construct the full forwarder resource name if needed
    if '/' not in forwarder_id:
      forwarder_resource = f"{self.instance_id}/forwarders/{forwarder_id}"
    else:
      forwarder_resource = forwarder_id

    # Construct the import URL
    url = f"{self.base_url}/{self.instance_id}/logTypes/{log_type}/logs:import"

    # Generate a unique ID for this log entry
    log_id = str(uuid.uuid4())

    # Construct the request payload
    payload = {
      "inline_source": {
        "logs": [
          {
            "name": f"{self.instance_id}/logTypes/{log_type}/logs/{log_id}",
            "data": base64.b64encode(log.encode('utf-8')).decode('utf-8'),
            "log_entry_time": log_entry_time_str,
            "collection_time": collection_time_str
          } for log in logs
        ],
        "forwarder": forwarder_resource
      }
    }

    # Send the request
    response = self.session.post(url, json=payload)

    # Check for errors
    if response.status_code != 200:
      raise Exception(f"Failed to ingest log: {response.text}")

    return response.json()

class SecOpsClient:
  """Main client class for interacting with Google SecOps."""

  def __init__(
          self,
          credentials: Optional[Credentials] = None,
          service_account_path: Optional[str] = None,
          service_account_info: Optional[Dict[str, Any]] = None
  ):
    """Initialize the SecOps client.

    Args:
        credentials: Optional pre-existing Google Auth credentials
        service_account_path: Optional path to service account JSON key file
        service_account_info: Optional service account JSON key data as dict
    """
    self.auth = SecOpsAuth(
      credentials=credentials,
      service_account_path=service_account_path,
      service_account_info=service_account_info
    )
    self._chronicle = None

  def chronicle(self, customer_id: str, project_id: str, region: str = "us") -> ChronicleClient:
    """Get Chronicle API client.

    Args:
        customer_id: Chronicle customer ID
        project_id: GCP project ID
        region: Chronicle API region (default: "us")

    Returns:
        ChronicleClient instance
    """
    return ChronicleClient(
      customer_id=customer_id,
      project_id=project_id,
      region=region,
      auth=self.auth
    )


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
