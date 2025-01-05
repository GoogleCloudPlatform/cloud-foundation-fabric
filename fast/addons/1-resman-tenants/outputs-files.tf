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

# tfdoc:file:description Output files persistence to local filesystem.

resource "local_file" "providers-simple" {
  for_each = var.outputs_location == null ? {} : {
    for k, v in local.tenants : k => local.tenant_data[k]
  }
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/providers/tenant-${each.key}.tf"
  content = templatefile(local._tpl_providers, {
    backend_extra = null
    bucket        = each.value.gcs_bucket
    name          = each.key
    sa            = each.value.service_account
  })
}

resource "local_file" "tfvars-simple" {
  for_each = var.outputs_location == null ? {} : {
    for k, v in local.tenants : k => local.tenant_data[k]
  }
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tfvars/tenant-${each.key}.auto.tfvars.json"
  content         = jsonencode(each.value)
}

resource "local_file" "providers" {
  for_each        = var.outputs_location == null ? {} : local.tenant_providers
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tenants/${each.key}/providers/1-resman-providers.tf"
  content         = try(each.value, null)
}

resource "local_file" "providers-r" {
  for_each        = var.outputs_location == null ? {} : local.tenant_providers_r
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tenants/${each.key}/providers/1-resman-r-providers.tf"
  content         = try(each.value, null)
}

resource "local_file" "tfvars" {
  # work around Terraform's botched ternary type check on maps
  for_each = {
    for k, v in local.tenant_tfvars : k => v if var.outputs_location != null
  }
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tenants/${each.key}/tfvars/0-bootstrap.auto.tfvars.json"
  content         = jsonencode(each.value)
}

resource "local_file" "tfvars_globals" {
  for_each        = var.outputs_location == null ? {} : local.tenant_globals
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tenants/${each.key}/tfvars/0-globals.auto.tfvars.json"
  content         = jsonencode(each.value)
}

resource "local_file" "workflows" {
  for_each        = var.outputs_location == null ? {} : local.tenant_cicd_workflows
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tenants/${each.key}/workflows/1-resman-workflow.yaml"
  content         = try(each.value, null)
}
