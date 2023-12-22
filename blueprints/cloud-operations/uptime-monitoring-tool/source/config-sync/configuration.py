#!/usr/bin/env python3
# Copyright 2023 Google LLC
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

from typing import Optional, Tuple
import requests

METADATA_HOST = "http://metadata.google.internal"


def get_metadata(metadata_path: str, alt: str = None) -> str:
  """Fetches metadata from the metadata server.

  Args:
      metadata_path: The path to the metadata endpoint.
      alt: (Optional) The alt metadata path to use.

  Returns:
      The metadata value.
  """
  params = {}
  if alt is not None:
    params["alt"] = alt

  response = requests.get(url=f"{METADATA_HOST}{metadata_path}", params=params,
                          headers={"Metadata-Flavor": "Google"})
  response.raise_for_status()
  return response.text


class Configuration:

  def __init__(self, project_id: str, pubsub_subscription: str):
    """Constructor."""
    self._project_id = project_id
    self._pubsub_subscription_path = pubsub_subscription

  @property
  def project_id(self):
    """Project-id where this daemon is running on."""
    return self._project_id

  @property
  def pubsub_subscription_path(self):
    """Pubsub topic where to listen for configuration updates."""
    return self._pubsub_subscription_path

  @staticmethod
  def load_from_metadata() -> 'Configuration':
    """Loads the configuration from instance metadata"""
    project_id = str(
        get_metadata(metadata_path="/computeMetadata/v1/project/project-id",
                     alt="text"))
    pubsub_subscription = str(
        get_metadata(
            metadata_path=
            "/computeMetadata/v1/instance/attributes/pubsub-subscription",
            alt="text"))

    return Configuration(project_id=project_id,
                         pubsub_subscription=pubsub_subscription)

  def __repr__(self):
    return self.__dict__


configuration = Configuration.load_from_metadata()
