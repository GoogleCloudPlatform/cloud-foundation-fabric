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

# tfdoc:file:description Instance-related locals and resources.

locals {
  # use lb subnets for instances if instance subnets are not defined
  subnets_instances = coalesce(
    var.vpc_config.subnets_instances, var.vpc_config.subnets
  )
  # derive instance names/attributes from permutation of regions and zones
  instances = {
    for t in setproduct(local.regions, var.instances_config.zones) :
    "${var.prefix}-${local.region_shortnames[t[0]]}-${t[1]}" => {
      region = t[0]
      zone   = "${t[0]}-${t[1]}"
    }
  }
}

module "instance-sa" {
  source       = "../../iam-service-account"
  project_id   = var.project_id
  name         = "vm-default"
  prefix       = var.prefix
  display_name = "Cross-region LB instances service account"
  iam_project_roles = {
    (var.project_id) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter"
    ]
  }
}

module "instances" {
  source        = "../../compute-vm"
  for_each      = local.instances
  project_id    = var.project_id
  zone          = each.value.zone
  name          = each.key
  instance_type = var.instances_config.machine_type
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }
  network_interfaces = [{
    network    = var.vpc_config.network
    subnetwork = local.subnets_instances[each.value.region]
  }]
  tags = [var.prefix]
  metadata = {
    user-data = file("${path.module}/nginx-cloud-config.yaml")
  }
  service_account = {
    email = module.instance-sa.email
  }
  group = {
    named_ports = {
      http  = 80
      https = 443
    }
  }
}
