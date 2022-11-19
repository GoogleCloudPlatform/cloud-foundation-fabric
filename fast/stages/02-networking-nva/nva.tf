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
  # routing_config should be aligned to the NVA network interfaces - i.e.
  # local.routing_config[0] sets up the first interface, and so on.
  routing_config = [
    {
      name = "untrusted"
      routes = [
        var.custom_adv.gcp_landing_untrusted_ew1,
        var.custom_adv.gcp_landing_untrusted_ew4,
      ]
    },
    {
      name = "trusted"
      routes = [
        var.custom_adv.gcp_dev_ew1,
        var.custom_adv.gcp_dev_ew4,
        var.custom_adv.gcp_landing_trusted_ew1,
        var.custom_adv.gcp_landing_trusted_ew4,
        var.custom_adv.gcp_prod_ew1,
        var.custom_adv.gcp_prod_ew4,
      ]
    },
  ]
  nva_locality = {
    europe-west1-b = { region = "europe-west1", trigram = "ew1", zone = "b" },
    europe-west1-c = { region = "europe-west1", trigram = "ew1", zone = "c" },
    europe-west4-b = { region = "europe-west4", trigram = "ew4", zone = "b" },
    europe-west4-c = { region = "europe-west4", trigram = "ew4", zone = "c" },
  }

}

# NVA config
module "nva-cloud-config" {
  source               = "../../../modules/cloud-config-container/simple-nva"
  enable_health_checks = true
  network_interfaces   = local.routing_config
}

module "nva-template" {
  for_each        = local.nva_locality
  source          = "../../../modules/compute-vm"
  project_id      = module.landing-project.project_id
  name            = "nva-template-${each.value.trigram}-${each.value.zone}"
  zone            = "${each.value.region}-${each.value.zone}"
  instance_type   = "e2-standard-2"
  tags            = ["nva"]
  create_template = true
  can_ip_forward  = true
  network_interfaces = [
    {
      network    = module.landing-untrusted-vpc.self_link
      subnetwork = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${each.value.trigram}"]
      nat        = false
      addresses  = null
    },
    {
      network    = module.landing-trusted-vpc.self_link
      subnetwork = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${each.value.trigram}"]
      nat        = false
      addresses  = null
    }
  ]
  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    size  = 10
    type  = "pd-balanced"
  }
  options = {
    allow_stopping_for_update = true
    deletion_protection       = false
    spot                      = true
    termination_action        = "STOP"
  }
  metadata = {
    user-data = module.nva-cloud-config.cloud_config
  }
}

module "nva-mig" {
  for_each          = local.nva_locality
  source            = "../../../modules/compute-mig"
  project_id        = module.landing-project.project_id
  location          = each.value.region
  name              = "nva-cos-${each.value.trigram}-${each.value.zone}"
  instance_template = module.nva-template[each.key].template.self_link
  target_size       = 1
  auto_healing_policies = {
    initial_delay_sec = 30
  }
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 22
    }
  }
}

module "ilb-nva-untrusted" {
  for_each      = { for l in local.nva_locality : l.region => l.trigram... }
  source        = "../../../modules/net-ilb"
  project_id    = module.landing-project.project_id
  region        = each.key
  name          = "nva-untrusted-${each.value.0}"
  service_label = var.prefix
  global_access = true
  vpc_config = {
    network    = module.landing-untrusted-vpc.self_link
    subnetwork = module.landing-untrusted-vpc.subnet_self_links["${each.key}/landing-untrusted-default-${each.value.0}"]
  }
  backends = [
    for key, _ in local.nva_locality : {
      group = module.nva-mig[key].group_manager.instance_group
    } if local.nva_locality[key].region == each.key
  ]
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 22
    }
  }
}


module "ilb-nva-trusted" {
  for_each      = { for l in local.nva_locality : l.region => l.trigram... }
  source        = "../../../modules/net-ilb"
  project_id    = module.landing-project.project_id
  region        = each.key
  name          = "nva-trusted-${each.value.0}"
  service_label = var.prefix
  global_access = true
  vpc_config = {
    network    = module.landing-trusted-vpc.self_link
    subnetwork = module.landing-trusted-vpc.subnet_self_links["${each.key}/landing-trusted-default-${each.value.0}"]
  }
  backends = [
    for key, _ in local.nva_locality : {
      group = module.nva-mig[key].group_manager.instance_group
    } if local.nva_locality[key].region == each.key
  ]
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 22
    }
  }
}

