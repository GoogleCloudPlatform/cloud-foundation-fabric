# Copyright 2026 Google LLC
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

project_id             = "test-project"
prefix                 = "foo"
name                   = "test-workflow"
description            = "Test workflow"
region                 = "europe-west1"
call_log_level         = "LOG_ALL_CALLS"
service_account_create = true
service_account_roles  = ["roles/logging.logWriter"]
user_env_vars = {
  TEST_KEY = "test_value"
}
source_contents = <<-EOT
  main:
    params: [args]
    steps:
      - step1:
          return: "OK"
EOT

iam = {
  "roles/workflows.invoker" = [
    "group:devops@example.com"
  ]
}

task_queues = {
  batch-tasks = {
    rate_limits = {
      max_dispatches_per_second = 10
      max_concurrent_dispatches = 5
    }
    retry_config = {
      max_attempts       = 5
      min_backoff        = "1s"
      max_backoff        = "30s"
      max_doublings      = 3
      max_retry_duration = "3600s"
    }
    stackdriver_logging_config = {
      sampling_ratio = 1.0
    }
  }
}

scheduler_jobs = {
  daily-batch = {
    schedule         = "0 2 * * *"
    time_zone        = "Etc/UTC"
    argument         = "{\"batch_size\": 100}"
    attempt_deadline = "300s"
    retry_config = {
      retry_count          = 3
      min_backoff_duration = "5s"
      max_backoff_duration = "60s"
      max_doublings        = 2
    }
  }
}

eventarc_triggers = {
  pubsub-events = {
    matching_criteria = [
      {
        attribute = "type"
        value     = "google.cloud.pubsub.topic.v1.messagePublished"
      }
    ]
    pubsub_topic = "projects/test-project/topics/workflow-events"
    retry_policy = {
      max_attempts = 5
    }
  }
}
