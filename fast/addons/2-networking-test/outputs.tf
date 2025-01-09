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

<<<<<<<< HEAD:fast/addons/2-networking-test/outputs.tf
output "instance_addresses" {
  description = "Instance names and addresses."
  value = {
    for k, v in module.instances : k => v.internal_ip
  }
}

output "instance_ssh" {
  description = "Instance SSH commands."
  value = {
    for k, v in module.instances : k => (
      "gcloud compute ssh ${k} --project ${v.instance.project} --zone ${v.instance.zone}"
    )
  }
}

output "service_account_emails" {
  description = "Service account emails."
  value = {
    for k, v in module.service-accounts : k => v.email
  }
========
locals {
  project_id = try(module.project[0].project_id, var.project_id)
}

module "project" {
  source         = "../../../modules/project"
  count          = var._fast_debug.skip_datasources == true ? 0 : 1
  name           = var.project_id
  project_create = false
  services = [
    "certificatemanager.googleapis.com",
    "networkmanagement.googleapis.com",
    "networksecurity.googleapis.com",
    "privateca.googleapis.com"
  ]
>>>>>>>> 630e7f40 (Implement FAST stage add-ons, refactor netsec as add-on (#2800)):fast/addons/2-networking-ngfw/main.tf
}
