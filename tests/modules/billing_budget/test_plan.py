# Copyright 2022 Google LLC
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

def test_pubsub(plan_runner):
  "Test number of resources created."
  _, resources = plan_runner(pubsub_topic='topic')
  assert len(resources) == 1
  resource = resources[0]
  assert resource['values']['all_updates_rule'] == [
      {'disable_default_iam_recipients': False,
       'monitoring_notification_channels': [],
       'pubsub_topic': 'topic',
       'schema_version': '1.0'}
  ]


def test_channel(plan_runner):
  _, resources = plan_runner(notification_channels='["channel"]')
  assert len(resources) == 1
  resource = resources[0]
  assert resource['values']['all_updates_rule'] == [
      {'disable_default_iam_recipients': True,
       'monitoring_notification_channels': ['channel'],
       'pubsub_topic': None,
       'schema_version': '1.0'}
  ]


def test_emails(plan_runner):
  email_recipients = '{project_id = "project", emails = ["a@b.com", "c@d.com"]}'
  _, resources = plan_runner(email_recipients=email_recipients)
  assert len(resources) == 3


def test_absolute_amount(plan_runner):
  "Test absolute amount budget."
  _, resources = plan_runner(pubsub_topic='topic', amount="100")
  assert len(resources) == 1
  resource = resources[0]

  amount = resource['values']['amount'][0]
  assert amount['last_period_amount'] is None
  assert amount['specified_amount'] == [{'nanos': None, 'units': '100'}]

  assert resource['values']['threshold_rules'] == [
      {'spend_basis': 'CURRENT_SPEND',
       'threshold_percent': 0.5},
      {'spend_basis': 'CURRENT_SPEND',
          'threshold_percent': 1},
      {'spend_basis': 'FORECASTED_SPEND',
          'threshold_percent': 1}
  ]
