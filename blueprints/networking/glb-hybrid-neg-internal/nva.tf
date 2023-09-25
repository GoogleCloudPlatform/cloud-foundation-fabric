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

# tfdoc:file:description Network Virtual Appliances (NVAs).

module "nva_instance_templates" {
  for_each        = var.regions
  source          = "../../../modules/compute-vm"
  project_id      = module.project_landing.project_id
  can_ip_forward  = true
  create_template = true
  name            = "nva-${each.value}"
  service_account = {
    auto_create = true
  }
  zone = local.zones[each.key]
  metadata = {
    startup-script = templatefile(
      "${path.module}/data/nva-startup-script.tftpl",
      {
        gateway-trusted = cidrhost(module.vpc_landing_trusted.subnet_ips["${each.value}/trusted-${each.value}"], 1)
        spoke-primary   = var.ip_config.spoke_primary
        spoke-secondary = var.ip_config.spoke_secondary
      }
    )
  }
  network_interfaces = [
    {
      network    = module.vpc_landing_untrusted.self_link
      subnetwork = module.vpc_landing_untrusted.subnet_self_links["${each.value}/untrusted-${each.value}"]
    },
    {
      network    = module.vpc_landing_trusted.self_link
      subnetwork = module.vpc_landing_trusted.subnet_self_links["${each.value}/trusted-${each.value}"]
    }
  ]
  tags = [
    "http-server",
    "https-server",
    "ssh"
  ]
}

module "nva_migs" {
  for_each          = var.regions
  source            = "../../../modules/compute-mig"
  project_id        = module.project_landing.project_id
  location          = local.zones[each.key]
  name              = "nva-${each.value}"
  target_size       = 1
  instance_template = module.nva_instance_templates[each.key].template.self_link
}

module "nva_untrusted_ilbs" {
  for_each      = var.regions
  source        = "../../../modules/net-lb-int"
  project_id    = module.project_landing.project_id
  region        = each.value
  name          = "nva-ilb-${local.zones[each.key]}"
  service_label = "nva-ilb-${local.zones[each.key]}"
  vpc_config = {
    network    = module.vpc_landing_untrusted.self_link
    subnetwork = module.vpc_landing_untrusted.subnet_self_links["${each.value}/untrusted-${each.value}"]
  }
  backends = [{
    group = module.nva_migs[each.key].group_manager.instance_group
  }]
  health_check_config = {
    tcp = {
      port = 22
    }
  }
}
