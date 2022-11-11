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

from collections import Counter


def test_sinks(plan_runner):
  "Test folder-level sinks."
  tfvars = 'test.logging-sinks.tfvars'
  _, resources = plan_runner(tf_var_file=tfvars)
  assert len(resources) == 9

  resource_types = Counter([r["type"] for r in resources])
  assert resource_types == {
      "google_logging_folder_sink": 4,
      "google_folder": 1,
      "google_bigquery_dataset_iam_member": 1,
      "google_project_iam_member": 1,
      "google_pubsub_topic_iam_member": 1,
      "google_storage_bucket_iam_member": 1,
  }

  sinks = [r for r in resources if r["type"] == "google_logging_folder_sink"]
  assert sorted([r["index"] for r in sinks]) == [
      "debug",
      "info",
      "notice",
      "warning",
  ]
  values = [(
      r["index"],
      r["values"]["filter"],
      r["values"]["destination"],
      r["values"]["description"],
      r["values"]["include_children"],
      r["values"]["disabled"],
  ) for r in sinks]
  assert sorted(values) == [
      ("debug", "severity=DEBUG",
       "logging.googleapis.com/projects/myproject/locations/global/buckets/mybucket",
       "debug (Terraform-managed).", False, False),
      ("info", "severity=INFO",
       "bigquery.googleapis.com/projects/myproject/datasets/mydataset",
       "info (Terraform-managed).", True, True),
      ("notice", "severity=NOTICE",
       "pubsub.googleapis.com/projects/myproject/topics/mytopic",
       "notice (Terraform-managed).", False, False),
      ("warning", "severity=WARNING", "storage.googleapis.com/mybucket",
       "warning (Terraform-managed).", True, False),
  ]

  bindings = [r for r in resources if "member" in r["type"]]
  values = [(r["index"], r["type"], r["values"]["role"],
             r["values"]["condition"]) for r in bindings]
  assert sorted(values) == [
      ("debug", "google_project_iam_member", "roles/logging.bucketWriter", [{
          'expression':
              "resource.name.endsWith('projects/myproject/locations/global/buckets/mybucket')",
          'title':
              'debug bucket writer'
      }]),
      ("info", "google_bigquery_dataset_iam_member",
       "roles/bigquery.dataEditor", []),
      ("notice", "google_pubsub_topic_iam_member", "roles/pubsub.publisher",
       []),
      ("warning", "google_storage_bucket_iam_member",
       "roles/storage.objectCreator", []),
  ]

  exclusions = [(r["index"], r["values"]["exclusions"]) for r in sinks]
  assert sorted(exclusions) == [
      ("debug", [{
          "description": None,
          "disabled": False,
          "filter": "logName:compute",
          "name": "no-compute"
      }, {
          "description": None,
          "disabled": False,
          "filter": "logName:container",
          "name": "no-container"
      }]),
      ("info", []),
      ("notice", []),
      ("warning", []),
  ]


def test_exclusions(plan_runner):
  "Test folder-level logging exclusions."
  logging_exclusions = ("{"
                        'exclusion1 = "resource.type=gce_instance", '
                        'exclusion2 = "severity=NOTICE", '
                        "}")
  _, resources = plan_runner(logging_exclusions=logging_exclusions)
  assert len(resources) == 3
  exclusions = [
      r for r in resources if r["type"] == "google_logging_folder_exclusion"
  ]
  assert sorted([r["index"] for r in exclusions]) == [
      "exclusion1",
      "exclusion2",
  ]
  values = [(r["index"], r["values"]["filter"]) for r in exclusions]
  assert sorted(values) == [
      ("exclusion1", "resource.type=gce_instance"),
      ("exclusion2", "severity=NOTICE"),
  ]
