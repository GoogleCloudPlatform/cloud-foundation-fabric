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

# tfdoc:file:description Output files persistence to local filesystem.

locals {
  outputs_root = join("/", [
    try(pathexpand(var.outputs_location), ""),
    "tenants",
  ])
}

resource "local_file" "providers" {
  for_each        = var.outputs_location == null ? {} : var.tenant_configs
  file_permission = "0644"
  filename        = "${local.outputs_root}/${each.key}/providers/1-0-resman-providers.tf"
  content         = try(local.providers[each.key], null)
}

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : var.tenant_configs
  file_permission = "0644"
  filename        = "${local.outputs_root}/${each.key}/tfvars/0-0-bootstrap.auto.tfvars.json"
  content         = jsonencode(local.tfvars[each.key])
}

resource "local_file" "workflow" {
  for_each        = var.outputs_location == null ? {} : var.tenant_configs
  file_permission = "0644"
  filename        = "${local.outputs_root}/${each.key}/workflows/1-0-resman-${each.value.cicd.repository_type}.json"
  content         = try(local.workflows[each.key], null)
}
