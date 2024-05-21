/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description Per-tenant centrally managed resources.

locals {
  root_node = coalesce(var.root_node, "organizations/${var.organization.id}")
}

module "tenant-core-logbucket" {
  source        = "../../../modules/logging-bucket"
  for_each      = local.tenants
  parent_type   = "project"
  parent        = var.logging.project_id
  id            = "tenant-${each.key}-audit"
  location      = var.locations.logging
  log_analytics = { enable = true }
}

module "tenant-core-folder" {
  source   = "../../../modules/folder"
  for_each = local.tenants
  parent   = local.root_node
  name     = "${each.value.descriptive_name} Core"
  logging_sinks = {
    "tenant-${each.key}-audit" = {
      destination = module.tenant-core-logbucket[each.key].id
      filter      = <<-FILTER
        log_id("cloudaudit.googleapis.com/activity") OR
        log_id("cloudaudit.googleapis.com/system_event") OR
        log_id("cloudaudit.googleapis.com/policy") OR
        log_id("cloudaudit.googleapis.com/access_transparency")
      FILTER
      type        = "logging"
    }
  }
  org_policies = each.value.cloud_identity == null ? {} : {
    "iam.allowedPolicyMemberDomains" = {
      rules = [{
        allow = {
          values = compact([
            var.organization.customer_id,
            try(each.value.cloud_identity.customer_id, null)
          ])
        }
      }]
    }
  }
  tag_bindings = {
    tenant = try(
      module.organization.tag_values["${var.tag_names.tenant}/${each.key}"].id,
      null
    )
  }
}
