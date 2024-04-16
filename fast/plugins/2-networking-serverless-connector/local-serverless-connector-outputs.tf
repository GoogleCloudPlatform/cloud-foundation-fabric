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

# tfdoc:file:description Serverless Connector outputs.

locals {
  plugin_sc_tfvars = {
    dev  = google_vpc_access_connector.dev-primary[0].id
    prod = google_vpc_access_connector.prod-primary[0].id
  }
}

# generate tfvars file for subsequent stages

resource "local_file" "plugin_sc_tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tfvars/2-networking-serverless-connnector.auto.tfvars.json"
  content = jsonencode({
    vpc_connectors = local.plugin_sc_tfvars
  })
}

resource "google_storage_bucket_object" "plugin_sc_tfvars" {
  bucket = var.automation.outputs_bucket
  name   = "tfvars/2-networking-serverless-connnector.auto.tfvars.json"
  content = jsonencode({
    vpc_connectors = local.plugin_sc_tfvars
  })
}

# outputs

output "plugin_sc_connectors" {
  description = "VPC Access Connectors."
  value       = local.plugin_sc_tfvars
}
