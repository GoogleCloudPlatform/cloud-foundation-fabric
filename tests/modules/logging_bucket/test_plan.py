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


def test_project_logging_bucket(plan_runner):
  "Test project logging bucket."
  _, resources = plan_runner(parent_type="project", parent="myproject")
  assert len(resources) == 1

  resource = resources[0]
  assert resource["type"] == "google_logging_project_bucket_config"
  assert resource["values"] == {
      "bucket_id": "mybucket",
      "cmek_settings": [],
      "project": "myproject",
      "location": "global",
      "retention_days": 30,
  }


def test_folder_logging_bucket(plan_runner):
  "Test project logging bucket."
  _, resources = plan_runner(parent_type="folder", parent="folders/0123456789")
  assert len(resources) == 1

  resource = resources[0]
  assert resource["type"] == "google_logging_folder_bucket_config"
  assert resource["values"] == {
      "bucket_id": "mybucket",
      "cmek_settings": [],
      "folder": "folders/0123456789",
      "location": "global",
      "retention_days": 30,
  }


def test_organization_logging_bucket(plan_runner):
  "Test project logging bucket."
  _, resources = plan_runner(parent_type="organization",
                             parent="organizations/0123456789")
  assert len(resources) == 1

  resource = resources[0]
  assert resource["type"] == "google_logging_organization_bucket_config"
  assert resource["values"] == {
      "bucket_id": "mybucket",
      "cmek_settings": [],
      "organization": "organizations/0123456789",
      "location": "global",
      "retention_days": 30,
  }


def test_billing_account_logging_bucket(plan_runner):
  "Test project logging bucket."
  _, resources = plan_runner(parent_type="billing_account", parent="0123456789")
  assert len(resources) == 1

  resource = resources[0]
  assert resource["type"] == "google_logging_billing_account_bucket_config"
  assert resource["values"] == {
      "bucket_id": "mybucket",
      "cmek_settings": [],
      "billing_account": "0123456789",
      "location": "global",
      "retention_days": 30,
  }
