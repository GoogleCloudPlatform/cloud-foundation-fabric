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

# tfdoc:file:description Output files persistence to automation GCS bucket.

resource "google_storage_bucket_object" "providers-simple" {
  for_each = {
    for k, v in local.tenants : k => local.tenant_data[k]
  }
  bucket = var.automation.outputs_bucket
  name   = "providers/tenant-${each.key}.tf"
  content = templatefile(local._tpl_providers, {
    backend_extra = null
    bucket        = each.value.gcs_bucket
    name          = each.key
    sa            = each.value.service_account
  })
}

resource "google_storage_bucket_object" "tfvars-simple" {
  for_each = {
    for k, v in local.tenants : k => local.tenant_data[k]
  }
  bucket  = var.automation.outputs_bucket
  name    = "tfvars/tenant-${each.key}.auto.tfvars.json"
  content = jsonencode(each.value)
}

resource "google_storage_bucket_object" "providers" {
  for_each = local.tenant_providers
  bucket   = module.tenant-automation-tf-output-gcs[each.key].name
  name     = "providers/1-resman-providers.tf"
  content  = each.value
}

resource "google_storage_bucket_object" "providers_r" {
  for_each = local.tenant_providers_r
  bucket   = module.tenant-automation-tf-output-gcs[each.key].name
  name     = "providers/1-resman-r-providers.tf"
  content  = each.value
}

resource "google_storage_bucket_object" "tfvars" {
  for_each = local.tenant_tfvars
  bucket   = module.tenant-automation-tf-output-gcs[each.key].name
  name     = "tfvars/0-bootstrap.auto.tfvars.json"
  content  = jsonencode(each.value)
}

resource "google_storage_bucket_object" "tfvars_globals" {
  for_each = local.tenant_globals
  bucket   = module.tenant-automation-tf-output-gcs[each.key].name
  name     = "tfvars/0-globals.auto.tfvars.json"
  content  = jsonencode(each.value)
}

resource "google_storage_bucket_object" "workflows" {
  for_each = local.tenant_cicd_workflows
  bucket   = module.tenant-automation-tf-output-gcs[each.key].name
  name     = "workflows/1-resman-workflow.yaml"
  content  = each.value
}
