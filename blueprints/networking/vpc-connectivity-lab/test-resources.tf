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

locals {
  test-vms = {
    ext = {
      network    = module.ext-vpc.self_link
      subnetwork = module.ext-vpc.subnet_self_links["${var.region}/ext"]
    }
    hub-a = {
      network    = module.hub-vpc.self_link
      subnetwork = module.hub-vpc.subnet_self_links["${var.region}/hub-a"]
    }
    hub-b = {
      network    = module.hub-vpc.self_link
      subnetwork = module.hub-vpc.subnet_self_links["${var.region}/hub-b"]
    }
    spoke-vpn-a = {
      network    = module.spoke-vpn-a-vpc.self_link
      subnetwork = module.spoke-vpn-a-vpc.subnet_self_links["${var.region}/vpn-a"]
    },
    spoke-peering-a = {
      network    = module.spoke-peering-a-vpc.self_link
      subnetwork = module.spoke-peering-a-vpc.subnet_self_links["${var.region}/peering-a"]
    },
    spoke-vpn-b = {
      network    = module.spoke-vpn-b-vpc.self_link
      subnetwork = module.spoke-vpn-b-vpc.subnet_self_links["${var.region}/vpn-b"]
    },
    spoke-peering-b = {
      network    = module.spoke-peering-b-vpc.self_link
      subnetwork = module.spoke-peering-b-vpc.subnet_self_links["${var.region}/peering-b"]
    },
  }
}

module "test-vms" {
  for_each   = var.test_vms ? local.test-vms : {}
  source     = "../../../modules/compute-vm"
  project_id = module.project.project_id
  zone       = "${var.region}-a"
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
      export DEB_VERSION=`lsb_release -c | awk  '{print $2}'`
      echo "deb https://packages.cloud.google.com/mirror/cloud-apt/$DEB_VERSION $DEB_VERSION main" > /etc/apt/sources.list
      echo "deb https://packages.cloud.google.com/mirror/cloud-apt/$DEB_VERSION-security $DEB_VERSION-security main" >> /etc/apt/sources.list
      echo "deb https://packages.cloud.google.com/mirror/cloud-apt/$DEB_VERSION-updates $DEB_VERSION-updates main" >> /etc/apt/sources.list
      apt update
      apt install -y iputils-ping bind9-dnsutils
    EOF
  }
}
