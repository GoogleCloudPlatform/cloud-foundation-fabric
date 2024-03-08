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

import logging
import os
import shutil
import tempfile
from google.cloud import pubsub_v1
from google.cloud import storage
from configuration import configuration

logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)
l = logging.getLogger(__name__)


def handle_pubsub_message(message: pubsub_v1.subscriber.message.Message):
  """
  Handler for processing messages received from the Pub/Sub subscription.

  Args:
      message: The Pub/Sub message object containing the notification data.
  """
  l.debug("New PubSub message received: %s", str(message))

  # Retrieve the expected parameters from the message
  try:
    event_type = message.attributes["eventType"]
    bucket_id = message.attributes["bucketId"]
    object_id = message.attributes["objectId"]
  except KeyError as e:
    l.error(f"Invalid pubsub message: {message}. Missing attribute: {e}")
    message.ack()  # Acknowledge the message to prevent redelivery
    return

  # Handle only OBJECT_FINALIZE messages
  if event_type != "OBJECT_FINALIZE":
    l.debug("Skip this message as its type is different from OBJECT_FINALIZE.")
    message.ack()
    return

  # Download the new configuration file
  with tempfile.NamedTemporaryFile() as tmp:
    try:
      l.info("Fetching new config file from gs://%s/%s", bucket_id, object_id)
      storage_client = storage.Client(configuration.project_id)
      bucket = storage_client.get_bucket(bucket_id)
      blob = bucket.blob(object_id)
      blob.download_to_file(file_obj=tmp)

      tmp.flush()
      l.info("New net monitoring configuration loaded to %s", tmp.name)
    except:
      l.exception("Failed to download the configuration file from bucket.")
      return

    # Apply the new configuration
    try:
      shutil.copyfile(
          tmp.name,
          os.path.join("/etc/supervisor/conf.d/", "net-mon-agent.conf"),
      )
      os.system(
          "/usr/bin/supervisorctl reread && /usr/bin/supervisorctl update")
      l.info("Network monitoring configuration updated and reloaded")
    except Exception as e:
      l.exception("Failed to apply configuration. Error: %s", str(e))
      return

    # Acknowledge the message after successfully processing it
    message.ack()


def main() -> None:
  """
  Entry point for the conf_reloader daemon.
  """
  l.info("Starting config sync daemon.")

  # Subscribe to the Pub/Sub topic where configuration file changes happen
  subscriber = pubsub_v1.SubscriberClient()
  subscription_path = subscriber.subscription_path(
      configuration.project_id, configuration.pubsub_subscription_path)
  streaming_pull_future = subscriber.subscribe(subscription_path,
                                               callback=handle_pubsub_message)
  l.info(f"Listening for messages on {subscription_path}.")

  # Wait for new configuration being pushed
  with subscriber:
    try:
      # The following line will wait indefinitely until a message/exception occurs.
      streaming_pull_future.result()
    except TimeoutError:
      streaming_pull_future.cancel()  # Trigger the shutdown.
      streaming_pull_future.result()  # Block until the shutdown is complete.


if __name__ == "__main__":
  main()
