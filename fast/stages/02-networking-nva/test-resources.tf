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

# tfdoc:file:description temporary instances for testing

# # Untrusted (Landing)

# module "test-vm-landing-untrusted-ew1-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.landing-project.project_id
#   zone       = "europe-west1-b"
#   name       = "test-vm-lnd-unt-ew1-0"
#   network_interfaces = [{
#     network    = module.landing-untrusted-vpc.self_link
#     subnetwork = module.landing-untrusted-vpc.subnet_self_links["europe-west1/landing-untrusted-default-ew1"]
#   }]
#   tags                   = ["ew1", "ssh"]
#   service_account_create = true
#   boot_disk = {
#     image = "projects/debian-cloud/global/images/family/debian-10"
#   }
#   options = {
#     spot                      = true
#     termination_action        = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# module "test-vm-landing-untrusted-ew4-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.landing-project.project_id
#   zone       = "europe-west4-a"
#   name       = "test-vm-lnd-unt-ew4-0"
#   network_interfaces = [{
#     network    = module.landing-untrusted-vpc.self_link
#     subnetwork = module.landing-untrusted-vpc.subnet_self_links["europe-west4/landing-untrusted-default-ew4"]
#   }]
#   tags                   = ["ew4", "ssh"]
#   service_account_create = true
#   boot_disk = {
#     image = "projects/debian-cloud/global/images/family/debian-10"
#   }
#   options = {
#     spot                      = true
#     termination_action        = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# # Trusted (hub)

# module "test-vm-landing-trusted-ew1-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.landing-project.project_id
#   zone       = "europe-west1-b"
#   name       = "test-vm-lnd-tru-ew1-0"
#   network_interfaces = [{
#     network    = module.landing-trusted-vpc.self_link
#     subnetwork = module.landing-trusted-vpc.subnet_self_links["europe-west1/landing-trusted-default-ew1"]
#   }]
#   tags                   = ["ew1", "ssh"]
#   service_account_create = true
#   boot_disk = {
#     image = "projects/debian-cloud/global/images/family/debian-10"
#   }
#   options = {
#     spot                      = true
#     termination_action        = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# module "test-vm-landing-trusted-ew4-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.landing-project.project_id
#   zone       = "europe-west4-a"
#   name       = "test-vm-lnd-tru-ew4-0"
#   network_interfaces = [{
#     network    = module.landing-trusted-vpc.self_link
#     subnetwork = module.landing-trusted-vpc.subnet_self_links["europe-west4/landing-trusted-default-ew4"]
#   }]
#   tags                   = ["ew4", "ssh"]
#   service_account_create = true
#   boot_disk = {
#     image = "projects/debian-cloud/global/images/family/debian-10"
#   }
#   options = {
#     spot                      = true
#     termination_action        = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# # Dev spoke

# module "test-vm-dev-ew1-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.dev-spoke-project.project_id
#   zone       = "europe-west1-b"
#   name       = "test-vm-dev-ew1-0"
#   network_interfaces = [{
#     network = module.dev-spoke-vpc.self_link
#     # change the subnet name to match the values you are actually using
#     subnetwork = module.dev-spoke-vpc.subnet_self_links["europe-west1/dev-default-ew1"]
#   }]
#   tags                   = ["ew1", "ssh"]
#   service_account_create = true
#   boot_disk = {
#     image = "projects/debian-cloud/global/images/family/debian-10"
#   }
#   options = {
#     spot                      = true
#     termination_action        = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# module "test-vm-dev-ew4-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.dev-spoke-project.project_id
#   zone       = "europe-west4-a"
#   name       = "test-vm-dev-ew4-0"
#   network_interfaces = [{
#     network = module.dev-spoke-vpc.self_link
#     # change the subnet name to match the values you are actually using
#     subnetwork = module.dev-spoke-vpc.subnet_self_links["europe-west4/dev-default-ew4"]
#   }]
#   tags                   = ["ew4", "ssh"]
#   service_account_create = true
#   boot_disk = {
#     image = "projects/debian-cloud/global/images/family/debian-10"
#   }
#   options = {
#     spot                      = true
#     termination_action        = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# # Prod spoke

# module "test-vm-prod-ew1-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.prod-spoke-project.project_id
#   zone       = "europe-west1-b"
#   name       = "test-vm-prod-ew1-0"
#   network_interfaces = [{
#     network = module.prod-spoke-vpc.self_link
#     # change the subnet name to match the values you are actually using
#     subnetwork = module.prod-spoke-vpc.subnet_self_links["europe-west1/prod-default-ew1"]
#   }]
#   tags                   = ["ew1", "ssh"]
#   service_account_create = true
#   boot_disk = {
#     image = "projects/debian-cloud/global/images/family/debian-10"
#     type  = "pd-balanced"
#     size  = 10
#   }
#   options = {
#     spot                      = true
#     termination_action        = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# module "test-vm-prod-ew4-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.prod-spoke-project.project_id
#   zone       = "europe-west4-a"
#   name       = "test-vm-prod-ew4-0"
#   network_interfaces = [{
#     network = module.prod-spoke-vpc.self_link
#     # change the subnet name to match the values you are actually using
#     subnetwork = module.prod-spoke-vpc.subnet_self_links["europe-west4/prod-default-ew4"]
#   }]
#   tags                   = ["ew4", "ssh"]
#   service_account_create = true
#   boot_disk = {
#     image = "projects/debian-cloud/global/images/family/debian-10"
#   }
#   options = {
#     spot                      = true
#     termination_action        = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }
