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

resource "google_iam_workload_identity_pool" "pool" {
  provider                  = google-beta
  project                   = var.project_id
  workload_identity_pool_id = var.workload_identity_pool_id
}

resource "google_iam_workload_identity_pool_provider" "providers" {
  for_each                           = var.workload_identity_pool_providers
  provider                           = google-beta
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = each.key
  display_name                       = each.value.display_name
  description                        = each.value.description
  disabled                           = each.value.disabled
  attribute_condition                = each.value.attribute_condition
  attribute_mapping                  = each.value.attribute_mapping

  dynamic "aws" {
    for_each = try(each.value.aws, null) == null ? [] : [""]
    content {
      account_id = each.value.aws.account_id
    }
  }

  dynamic "oidc" {
    for_each = try(each.value.oidc, null) == null ? [] : [""]
    content {
      allowed_audiences = each.value.oidc.allowed_audiences
      issuer_uri        = each.value.oidc.issuer_uri
    }
  }

}
