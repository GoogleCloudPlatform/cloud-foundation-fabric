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

# tfdoc:file:description Temporary instances for testing

# module "test-vm-dev-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.dev-spoke-project.project_id
#   zone       = "${var.regions.primary}-b"
#   name       = "test-vm-0"
#   network_interfaces = [{
#     network = module.dev-spoke-vpc.self_link
#     # change the subnet name to match the values you are actually using
#     subnetwork = module.dev-spoke-vpc.subnet_self_links["${var.regions.primary}/dev-default-${local.region_shortnames[var.regions.primary]}"]
#     alias_ips  = {}
#     nat        = false
#     addresses  = null
#   }]
#   tags                   = ["ssh"]
#   service_account_create = true
#   boot_disk = {
#     image = "projects/debian-cloud/global/images/family/debian-10"
#     type  = "pd-balanced"
#     size  = 10
#   }
#   options = {
#     allow_stopping_for_update = true
#     deletion_protection       = false
#     spot                      = true
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping 	bind9-dnsutils
#     EOF
#   }
# }

# module "test-vm-prod-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.prod-spoke-project.project_id
#   zone       = "${var.regions.primary}-b"
#   name       = "test-vm-0"
#   network_interfaces = [{
#     network = module.prod-spoke-vpc.self_link
#     # change the subnet name to match the values you are actually using
#     subnetwork = module.prod-spoke-vpc.subnet_self_links["${var.regions.primary}/prod-default-${local.region_shortnames[var.regions.primary]}"]
#     alias_ips  = {}
#     nat        = false
#     addresses  = null
#   }]
#   tags                   = ["ssh"]
#   service_account_create = true
#   boot_disk = {
#     image = "projects/debian-cloud/global/images/family/debian-10"
#     type  = "pd-balanced"
#     size  = 10
#   }
#   options = {
#     allow_stopping_for_update = true
#     deletion_protection       = false
#     spot                      = true
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping 	bind9-dnsutils
#     EOF
#   }
# }
