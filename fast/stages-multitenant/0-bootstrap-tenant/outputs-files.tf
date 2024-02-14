/**
 * Copyright 2023 Google LLC
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

# tfdoc:file:description Output files persistence to local filesystem.

locals {
  outputs_root = join("/", [
    try(pathexpand(var.outputs_location), ""),
    "tenants",
    var.tenant_config.short_name
  ])
}

resource "local_file" "providers" {
  count           = var.outputs_location == null ? 0 : 1
  file_permission = "0644"
  filename        = "${local.outputs_root}/providers/1-resman-tenant-providers.tf"
  content         = try(local.provider, null)
}

resource "local_file" "tfvars" {
  count           = var.outputs_location == null ? 0 : 1
  file_permission = "0644"
  filename        = "${local.outputs_root}/tfvars/0-bootstrap-tenant.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "local_file" "workflows" {
  for_each        = var.outputs_location == null ? {} : local.cicd_workflows
  file_permission = "0644"
  filename        = "${local.outputs_root}/workflows/${each.key}-${local.cicd_repositories[each.key].type}.yaml"
  content         = each.value
}
