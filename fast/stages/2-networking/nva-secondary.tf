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

locals {
  routing_config_secondary = concat(local._routing_config, [
    {
      name = "transit_secondary"
      routes = [
        var.gcp_ranges.gcp_transit_secondary
      ]
    }
  ])
}

module "nva-cloud-config-secondary" {
  source               = "../../../modules/cloud-config-container/simple-nva"
  enable_health_checks = true
  network_interfaces   = local.routing_config_secondary
}


module "nva-secondary" {
  for_each       = toset(["a"])
  source         = "../../../modules/compute-vm"
  project_id     = module.net-project.project_id
  name           = "nva-secondary-${each.key}"
  zone           = "${var.regions.secondary}-${each.key}"
  instance_type  = "e2-standard-8"
  tags           = ["nva"]
  can_ip_forward = true
  network_interfaces = [
    {
      network    = module.external-vpc.self_link
      subnetwork = module.external-vpc.subnet_self_links["${var.regions.secondary}/prod-core-external-0-nva-secondary"]
      nat        = false
      addresses  = null
    },
    {
      network    = module.dmz-vpc.self_link
      subnetwork = module.dmz-vpc.subnet_self_links["${var.regions.secondary}/prod-core-dmz-0-nva-secondary"]
      nat        = false
      addresses  = null
    },
    {
      network    = module.mgmt-vpc.self_link
      subnetwork = module.mgmt-vpc.subnet_self_links["${var.regions.secondary}/prod-core-mgmt-0-nva-secondary"]
      nat        = false
      addresses  = null
    },
    {
      network    = module.shared-vpc.self_link
      subnetwork = module.shared-vpc.subnet_self_links["${var.regions.secondary}/prod-core-shared-0-nva-secondary"]
      nat        = false
      addresses  = null
    },
    {
      network    = module.transit-secondary-vpc.self_link
      subnetwork = module.transit-secondary-vpc.subnet_self_links["${var.regions.secondary}/prod-core-transit-secondary-0-nva"]
      nat        = false
      addresses  = null
    },
  ]
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }
  options = {
    allow_stopping_for_update = true
    deletion_protection       = false
    spot                      = true
    termination_action        = "STOP"
  }
  metadata = {
    user-data = module.nva-cloud-config-secondary.cloud_config
  }
}

resource "google_compute_instance_group" "nva-secondary" {
  for_each    = toset(["a"])
  name        = "nva-secondary-ig-${each.key}"
  description = "NVA instance group for the secondary region, zone ${each.key}."
  zone        = "${var.regions.secondary}-${each.key}"
  project     = module.net-project.project_id
  network     = module.external-vpc.self_link
  instances   = toset([module.nva-secondary[each.key].self_link])
}

