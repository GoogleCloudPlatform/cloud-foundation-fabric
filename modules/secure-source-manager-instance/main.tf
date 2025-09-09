/**
 * Copyright 2025 Google LLC
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
  branch_rules = merge([
    for k1, v1 in var.repositories : {
      for k2, v2 in v1.branch_rules : "${k1}.${k2}" => {
        repository                = k1
        branch_rule_id            = k2
        include_pattern           = v2.include_pattern
        minimum_approvals_count   = v2.minimum_approvals_count
        minimum_reviews_count     = v2.minimum_reviews_count
        require_comments_resolved = v2.require_comments_resolved
        require_linear_history    = v2.require_linear_history
        require_pull_request      = v2.require_pull_request
        disabled                  = v2.disabled
        allow_stale_reviews       = v2.allow_stale_reviews
      }
    }
  ]...)
}

resource "google_secure_source_manager_instance" "instance" {
  count       = var.instance_create ? 1 : 0
  instance_id = var.instance_id
  project     = var.project_id
  location    = var.location
  labels      = var.labels
  kms_key     = var.kms_key
  dynamic "private_config" {
    for_each = var.private_configs.is_private ? [""] : []
    content {
      is_private = true
      ca_pool    = var.private_configs.ca_pool_id
    }
  }
}

resource "google_secure_source_manager_repository" "repositories" {
  for_each      = var.repositories
  repository_id = each.key
  instance      = try(google_secure_source_manager_instance.instance[0].name, "projects/${var.project_id}/locations/${var.location}/instances/${var.instance_id}")
  project       = var.project_id
  location      = var.location
  description   = each.value.description
  dynamic "initial_config" {
    for_each = each.value.initial_config == null ? [] : [""]
    content {
      default_branch = each.value.initial_config.default_branch
      gitignores     = each.value.initial_config.gitignores
      license        = each.value.initial_config.license
      readme         = each.value.initial_config.readme
    }
  }
}

resource "google_secure_source_manager_branch_rule" "branch_rules" {
  for_each                  = local.branch_rules
  branch_rule_id            = each.value.branch_rule_id
  project                   = google_secure_source_manager_repository.repositories[each.value.repository].project
  location                  = google_secure_source_manager_repository.repositories[each.value.repository].location
  repository_id             = google_secure_source_manager_repository.repositories[each.value.repository].repository_id
  disabled                  = each.value.disabled
  include_pattern           = each.value.include_pattern
  minimum_approvals_count   = each.value.minimum_approvals_count
  minimum_reviews_count     = each.value.minimum_reviews_count
  require_comments_resolved = each.value.require_comments_resolved
  require_linear_history    = each.value.require_linear_history
  require_pull_request      = each.value.require_pull_request
  allow_stale_reviews       = each.value.allow_stale_reviews
}
