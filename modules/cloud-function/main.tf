/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  prefix = var.prefix == null ? "" : "${var.prefix}-"
}


###############################################################################
#                      Cloud Function and GCS code bundle                     #
###############################################################################

resource "google_cloudfunctions_function" "function" {
  project               = var.project_id
  region                = var.region
  name                  = "${local.prefix}${var.name}"
  description           = "Terraform managed."
  runtime               = var.function_config.runtime
  available_memory_mb   = var.function_config.memory
  max_instances         = var.function_config.instances
  timeout               = var.function_config.timeout
  entry_point           = var.function_config.entry_point
  environment_variables = var.environment_variables
  service_account_email = google_service_account.service_account.email
  source_archive_bucket = local.bucket
  source_archive_object = google_storage_bucket_object.bundle.name

  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = google_pubsub_topic.topic.id
  }

}

resource "google_storage_bucket" "bucket" {
  count   = var.bucket_name == null ? 1 : 0
  project = var.project_id
  name    = lookup(local.prefixes, "bucket", var.name)
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = "30"
    }
  }
}

resource "google_storage_bucket_object" "bundle" {
  name   = "bundle-${data.archive_file.bundle.output_md5}.zip"
  bucket = local.bucket
  source = data.archive_file.bundle.output_path
}

data "archive_file" "bundle" {
  type        = "zip"
  source_dir  = var.bundle_config.source_dir
  output_path = var.bundle_config.output_path
}
