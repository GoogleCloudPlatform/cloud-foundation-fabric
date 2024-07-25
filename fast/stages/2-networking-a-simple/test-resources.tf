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

# tfdoc:file:description Temporary instances for testing

locals {
  test-vms = var.create_test_instances != true ? {} : merge(
    {
      dev-spoke-primary = {
        region     = var.regions.primary
        project_id = module.dev-spoke-project.project_id
        zone       = "b"
        network    = module.dev-spoke-vpc.self_link
        subnetwork = module.dev-spoke-vpc.subnet_self_links["${var.regions.primary}/dev-default"]
      }
      prod-spoke-primary = {
        region     = var.regions.primary
        project_id = module.prod-spoke-project.project_id
        zone       = "b"
        network    = module.prod-spoke-vpc.self_link
        subnetwork = module.prod-spoke-vpc.subnet_self_links["${var.regions.primary}/prod-default"]
      }
    },
    local.spoke_connection == "ncc" ? {} :
    {
      landing-primary = {
        region     = var.regions.primary
        project_id = module.landing-project.project_id
        zone       = "b"
        network    = module.landing-vpc.self_link
        subnetwork = module.landing-vpc.subnet_self_links["${var.regions.primary}/landing-default"]
      }
  })
}

module "test-vms" {
  for_each = local.test-vms
  # for_each   = {}
  source     = "../../../modules/compute-vm"
  project_id = each.value.project_id
  zone       = "${each.value.region}-${each.value.zone}"
  name       = "test-vm-${each.key}"
  network_interfaces = [{
    network = each.value.network
    # change the subnet name to match the values you are actually using
    subnetwork = each.value.subnetwork
  }]
  instance_type = "e2-micro"
  tags          = ["ssh"]
  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-11"
    }
  }
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install -y iputils-ping bind9-dnsutils
    EOF
  }
}
