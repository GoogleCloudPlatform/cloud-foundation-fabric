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
  # combine factory and variable instances, clean up subnet self links
  _all_instances = {
    for k, v in merge(var.test_instances, local.factory_instances) :
    k => merge(v, {
      subnet_id = replace(
        v.subnet_id, "https://www.googleapis.com/compute/v1/", ""
      )
    })
  }
  _all_service_accounts = merge(
    var.test_service_accounts, local.factory_service_accounts
  )
}

module "service-accounts" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.service_accounts
  project_id   = each.value.project_id
  name         = "${var.name}-${each.key}"
  display_name = each.value.display_name
  iam_project_roles = merge(
    each.value.iam_project_roles,
    {
      (each.value.project_id) = distinct(concat(
        lookup(each.value.iam_project_roles, each.value.project_id, []),
        [
          "roles/logging.logWriter",
          "roles/monitoring.metricWriter"
        ]
      ))
    }
  )
}

module "instances" {
  source        = "../../../modules/compute-vm"
  for_each      = { for k in local.instances : k.name => k }
  project_id    = each.value.project_id
  zone          = each.value.zone
  name          = each.key
  instance_type = each.value.type
  boot_disk = {
    initialize_params = {
      image = each.value.image
    }
  }
  network_interfaces = [{
    network    = each.value.network_id
    subnetwork = each.value.subnet_id
  }]
  tags = each.value.tags
  metadata = merge(
    each.value.metadata, each.value.user_data_file == null ? {} : {
      user-data = file(each.value.user_data_file)
    }
  )
  service_account = {
    email = lookup(
      local.service_account_emails,
      each.value.service_account,
      each.value.service_account
    )
  }
}
