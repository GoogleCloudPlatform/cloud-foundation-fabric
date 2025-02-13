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

module "backend-vm-addresses" {
  source     = "../../../../modules/net-address"
  project_id = local.project_id
  internal_addresses = {
    for k, v in var.backend_vm_configs
    : k => {
      address    = v.address
      name       = "${var.prefix}-backend-ip-${k}"
      region     = var.region
      subnetwork = module.vpc-dataplane.subnet_self_links["${var.region}/${var.prefix}-dataplane"]
    }
  }
}

module "backends-sa" {
  source     = "../../../../modules/iam-service-account"
  project_id = local.project_id
  name       = "${var.prefix}-backends-sa"
}

module "backend-vms" {
  for_each      = var.backend_vm_configs
  source        = "../../../../modules/compute-vm"
  project_id    = local.project_id
  zone          = "${var.region}-${each.key}"
  name          = "${var.prefix}-backend-${each.key}"
  instance_type = "e2-micro"
  network_interfaces = [
    {
      network    = module.vpc-dataplane.self_link
      subnetwork = module.vpc-dataplane.subnet_self_links["${var.region}/${var.prefix}-dataplane"]
      stack_type = "IPV4_IPV6"
      addresses = {
        internal = module.backend-vm-addresses.internal_addresses["${var.prefix}-backend-ip-${each.key}"].address
      }
    }
  ]
  service_account = {
    email = module.backends-sa.email
  }
}
