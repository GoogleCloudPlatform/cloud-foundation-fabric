# Copyright 2021 Google LLC
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


import os
import pytest

from collections import Counter

FIXTURES_DIR = os.path.join(os.path.dirname(__file__), "fixture")


def test_sinks(plan_runner):
    "Test folder-level sinks."
    logging_sinks = """ {
    warning = {
      type          = "gcs"
      destination   = "mybucket"
      filter        = "severity=WARNING"
      iam           = true
      exclusions    = {}
      unique_writer = false
    }
    info = {
      type        = "bigquery"
      destination = "projects/myproject/datasets/mydataset"
      filter      = "severity=INFO"
      iam         = true
      exclusions  = {}
      unique_writer = false
    }
    notice = {
      type          = "pubsub"
      destination   = "projects/myproject/topics/mytopic"
      filter        = "severity=NOTICE"
      iam           = true
      exclusions    = {}
      unique_writer = false
    }
    debug = {
      type          = "logging"
      destination   = "projects/myproject/locations/global/buckets/mybucket"
      filter        = "severity=DEBUG"
      iam           = true
      exclusions    = {
        no-compute   = "logName:compute"
        no-container = "logName:container"
      }
      unique_writer = true
    }
  }
  """
    _, resources = plan_runner(FIXTURES_DIR, logging_sinks=logging_sinks)
    assert len(resources) == 9

    resource_types = Counter([r["type"] for r in resources])
    assert resource_types == {
        "google_logging_project_sink": 4,
        "google_bigquery_dataset_iam_member": 1,
        "google_project": 1,
        "google_project_iam_member": 1,
        "google_pubsub_topic_iam_member": 1,
        "google_storage_bucket_iam_member": 1,
    }

    sinks = [r for r in resources if r["type"] == "google_logging_project_sink"]
    assert sorted([r["index"] for r in sinks]) == [
        "debug",
        "info",
        "notice",
        "warning",
    ]
    values = [
        (
            r["index"],
            r["values"]["filter"],
            r["values"]["destination"],
            r["values"]["unique_writer_identity"],
        )
        for r in sinks
    ]
    assert sorted(values) == [
        (
            "debug",
            "severity=DEBUG",
            "logging.googleapis.com/projects/myproject/locations/global/buckets/mybucket",
            True,
        ),
        (
            "info",
            "severity=INFO",
            "bigquery.googleapis.com/projects/myproject/datasets/mydataset",
            False,
        ),
        (
            "notice",
            "severity=NOTICE",
            "pubsub.googleapis.com/projects/myproject/topics/mytopic",
            False,
        ),
        ("warning", "severity=WARNING", "storage.googleapis.com/mybucket", False),
    ]

    bindings = [r for r in resources if "member" in r["type"]]
    values = [(r["index"], r["type"], r["values"]["role"]) for r in bindings]
    assert sorted(values) == [
        ("debug", "google_project_iam_member", "roles/logging.bucketWriter"),
        ("info", "google_bigquery_dataset_iam_member", "roles/bigquery.dataEditor"),
        ("notice", "google_pubsub_topic_iam_member", "roles/pubsub.publisher"),
        ("warning", "google_storage_bucket_iam_member", "roles/storage.objectCreator"),
    ]

    exclusions = [(r["index"], r["values"]["exclusions"]) for r in sinks]
    assert sorted(exclusions) == [
        (
            "debug",
            [
                {
                    "description": None,
                    "disabled": False,
                    "filter": "logName:compute",
                    "name": "no-compute",
                },
                {
                    "description": None,
                    "disabled": False,
                    "filter": "logName:container",
                    "name": "no-container",
                },
            ],
        ),
        ("info", []),
        ("notice", []),
        ("warning", []),
    ]


def test_exclusions(plan_runner):
    "Test folder-level logging exclusions."
    logging_exclusions = (
        "{"
        'exclusion1 = "resource.type=gce_instance", '
        'exclusion2 = "severity=NOTICE", '
        "}"
    )
    _, resources = plan_runner(FIXTURES_DIR, logging_exclusions=logging_exclusions)
    assert len(resources) == 3
    exclusions = [
        r for r in resources if r["type"] == "google_logging_project_exclusion"
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
