/**
 * Copyright 2022 Google LLC
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
  pool_display_name     = var.display_name != "" ? var.display_name : var.pool_id
  provider_display_name = var.provider_display_name != "" ? var.provider_display_name : var.provider_id
}

resource "google_iam_workload_identity_pool" "default_pool" {
  workload_identity_pool_id = var.pool_id
  display_name              = local.pool_display_name
  disabled                  = var.disabled
  project                   = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "default_pool_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.default_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = local.provider_display_name
  disabled                           = var.provider_disabled
  attribute_condition                = var.provider_attribute_condition
  attribute_mapping                  = var.provider_attribute_mapping

  dynamic "oidc" {
    for_each = var.provider_config.oidc != null ? [var.provider_config.oidc] : []
    iterator = config
    content {
      allowed_audiences = config.value.allowed_audiences
      issuer_uri        = config.value.issuer_uri
    }
  }

  dynamic "aws" {
    for_each = var.provider_config.aws != null ? [var.provider_config.aws] : []
    iterator = config
    content {
      account_id = config.value.account_id
    }
  }

}