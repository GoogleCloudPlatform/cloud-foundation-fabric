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

# tfdoc:file:description temporary instances for testing

# module "test-vm-dmz-primary-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.landing-project.project_id
#   zone       = "${var.regions.primary}-b"
#   name       = "test-vm-lnd-unt-primary-0"
#   network_interfaces = [{
#     network    = module.dmz-vpc.self_link
#     subnetwork = module.dmz-vpc.subnet_self_links["${var.regions.primary}/dmz-default-${local.region_shortnames[var.regions.primary]}"]
#   }]
#   tags = ["primary", "ssh"]
#   boot_disk = {
#     initialize_params = {
#       image = "projects/debian-cloud/global/images/family/debian-11"
#     }
#   }
#   options = {
#     spot               = true
#     termination_action = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# module "test-vm-dmz-secondary-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.landing-project.project_id
#   zone       = "${var.regions.secondary}-a"
#   name       = "test-vm-lnd-unt-secondary-0"
#   network_interfaces = [{
#     network    = module.dmz-vpc.self_link
#     subnetwork = module.dmz-vpc.subnet_self_links["${var.regions.secondary}/dmz-default-${local.region_shortnames[var.regions.secondary]}"]
#   }]
#   tags = ["secondary", "ssh"]
#   boot_disk = {
#     initialize_params = {
#       image = "projects/debian-cloud/global/images/family/debian-11"
#     }
#   }
#   options = {
#     spot               = true
#     termination_action = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# # Landing (hub)

# module "test-vm-landing-primary-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.landing-project.project_id
#   zone       = "${var.regions.primary}-b"
#   name       = "test-vm-lnd-tru-primary-0"
#   network_interfaces = [{
#     network    = module.landing-vpc.self_link
#     subnetwork = module.landing-vpc.subnet_self_links["${var.regions.primary}/landing-default"]
#   }]
#   tags = ["primary", "ssh"]
#   boot_disk = {
#     initialize_params = {
#       image = "projects/debian-cloud/global/images/family/debian-11"
#     }
#   }
#   options = {
#     spot               = true
#     termination_action = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# module "test-vm-landing-secondary-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.landing-project.project_id
#   zone       = "${var.regions.secondary}-a"
#   name       = "test-vm-lnd-tru-secondary-0"
#   network_interfaces = [{
#     network    = module.landing-vpc.self_link
#     subnetwork = module.landing-vpc.subnet_self_links["${var.regions.secondary}/landing-default"]
#   }]
#   tags = ["secondary", "ssh"]
#   boot_disk = {
#     initialize_params = {
#       image = "projects/debian-cloud/global/images/family/debian-11"
#     }
#   }
#   options = {
#     spot               = true
#     termination_action = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# # Dev spoke

# module "test-vm-dev-primary-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.dev-spoke-project.project_id
#   zone       = "${var.regions.primary}-b"
#   name       = "test-vm-dev-primary-0"
#   network_interfaces = [{
#     network = module.dev-spoke-vpc.self_link
#     # change the subnet name to match the values you are actually using
#     subnetwork = module.dev-spoke-vpc.subnet_self_links["${var.regions.primary}/dev-default"]
#   }]
#   tags = ["primary", "ssh"]
#   boot_disk = {
#     initialize_params = {
#       image = "projects/debian-cloud/global/images/family/debian-11"
#     }
#   }
#   options = {
#     spot               = true
#     termination_action = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# module "test-vm-dev-secondary-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.dev-spoke-project.project_id
#   zone       = "${var.regions.secondary}-a"
#   name       = "test-vm-dev-secondary-0"
#   network_interfaces = [{
#     network = module.dev-spoke-vpc.self_link
#     # change the subnet name to match the values you are actually using
#     subnetwork = module.dev-spoke-vpc.subnet_self_links["${var.regions.secondary}/dev-default"]
#   }]
#   tags = ["secondary", "ssh"]
#   boot_disk = {
#     initialize_params = {
#       image = "projects/debian-cloud/global/images/family/debian-11"
#     }
#   }
#   options = {
#     spot               = true
#     termination_action = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# # Prod spoke

# module "test-vm-prod-primary-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.prod-spoke-project.project_id
#   zone       = "${var.regions.primary}-b"
#   name       = "test-vm-prod-primary-0"
#   network_interfaces = [{
#     network = module.prod-spoke-vpc.self_link
#     # change the subnet name to match the values you are actually using
#     subnetwork = module.prod-spoke-vpc.subnet_self_links["${var.regions.primary}/prod-default"]
#   }]
#   tags = ["primary", "ssh"]
#   boot_disk = {
#     initialize_params = {
#       image = "projects/debian-cloud/global/images/family/debian-11"
#     }
#   }
#   options = {
#     spot               = true
#     termination_action = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }

# module "test-vm-prod-secondary-0" {
#   source     = "../../../modules/compute-vm"
#   project_id = module.prod-spoke-project.project_id
#   zone       = "${var.regions.secondary}-a"
#   name       = "test-vm-prod-secondary-0"
#   network_interfaces = [{
#     network = module.prod-spoke-vpc.self_link
#     # change the subnet name to match the values you are actually using
#     subnetwork = module.prod-spoke-vpc.subnet_self_links["${var.regions.secondary}/prod-default"]
#   }]
#   tags = ["secondary", "ssh"]
#   boot_disk = {
#     initialize_params = {
#       image = "projects/debian-cloud/global/images/family/debian-11"
#     }
#   }
#   options = {
#     spot               = true
#     termination_action = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }
