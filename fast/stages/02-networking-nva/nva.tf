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
  _subnets = var.data_dir == null ? tomap({}) : {
    for f in fileset("${var.data_dir}/subnets", "**/*.yaml") :
    trimsuffix(basename(f), ".yaml") => yamldecode(file("${var.data_dir}/subnets/${f}"))
  }
  subnets = merge(
    { for k, v in local._subnets : "${k}-cidr" => v.ip_cidr_range },
    { for k, v in local._subnets : "${k}-gw" => cidrhost(v.ip_cidr_range, 1) }
  )
}

# europe-west1

module "nva-template-ew1" {
  source         = "../../../modules/compute-vm"
  project_id     = module.landing-project.project_id
  name           = "nva-template"
  zone           = "europe-west1-b"
  tags           = ["nva"]
  can_ip_forward = true
  network_interfaces = [
    {
      network    = module.landing-untrusted-vpc.self_link
      subnetwork = module.landing-untrusted-vpc.subnet_self_links["europe-west1/landing-untrusted-default-ew1"]
    },
    {
      network    = module.landing-trusted-vpc.self_link
      subnetwork = module.landing-trusted-vpc.subnet_self_links["europe-west1/landing-trusted-default-ew1"]
    }
  ]
  boot_disk = {
    image = "projects/debian-cloud/global/images/family/debian-10"
  }
  create_template = true
  instance_type   = "f1-micro"
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = templatefile(
      "${path.module}/data/nva-startup-script.tftpl",
      {
        dev-default-ew1-cidr           = local.subnets.dev-default-ew1-cidr
        dev-default-ew4-cidr           = local.subnets.dev-default-ew4-cidr
        gateway-trusted                = local.subnets.landing-trusted-default-ew1-gw
        gateway-untrusted              = local.subnets.landing-untrusted-default-ew1-gw
        landing-trusted-other-region   = local.subnets.landing-trusted-default-ew4-cidr
        landing-untrusted-other-region = local.subnets.landing-untrusted-default-ew4-cidr
        onprem-main-cidr               = var.onprem_cidr.main
        prod-default-ew1-cidr          = local.subnets.prod-default-ew1-cidr
        prod-default-ew4-cidr          = local.subnets.prod-default-ew4-cidr
      }
    )
  }
}

module "nva-mig-ew1" {
  source      = "../../../modules/compute-mig"
  project_id  = module.landing-project.project_id
  regional    = true
  location    = "europe-west1"
  name        = "nva-ew1"
  target_size = 2
  auto_healing_policies = {
    health_check      = module.nva-mig-ew1.health_check.self_link
    initial_delay_sec = 30
  }
  health_check_config = {
    type    = "tcp"
    check   = { port = 22 }
    config  = {}
    logging = true
  }
  default_version = {
    instance_template = module.nva-template-ew1.template.self_link
    name              = "default"
  }
}

module "ilb-nva-untrusted-ew1" {
  source        = "../../../modules/net-ilb"
  project_id    = module.landing-project.project_id
  region        = "europe-west1"
  name          = "ilb-nva-untrusted-ew1"
  service_label = var.prefix
  global_access = true
  network       = module.landing-untrusted-vpc.self_link
  subnetwork    = module.landing-untrusted-vpc.subnet_self_links["europe-west1/landing-untrusted-default-ew1"]
  backends = [{
    failover       = false
    group          = module.nva-mig-ew1.group_manager.instance_group
    balancing_mode = "CONNECTION"
  }]
  health_check_config = {
    type = "tcp", check = { port = 22 }, config = {}, logging = false
  }
}

module "ilb-nva-trusted-ew1" {
  source        = "../../../modules/net-ilb"
  project_id    = module.landing-project.project_id
  region        = "europe-west1"
  name          = "ilb-nva-trusted-ew1"
  service_label = var.prefix
  global_access = true
  network       = module.landing-trusted-vpc.self_link
  subnetwork    = module.landing-trusted-vpc.subnet_self_links["europe-west1/landing-trusted-default-ew1"]
  backends = [{
    failover       = false
    group          = module.nva-mig-ew1.group_manager.instance_group
    balancing_mode = "CONNECTION"
  }]
  health_check_config = {
    type = "tcp", check = { port = 22 }, config = {}, logging = false
  }
}

# europe-west4

module "nva-template-ew4" {
  source         = "../../../modules/compute-vm"
  project_id     = module.landing-project.project_id
  name           = "nva-template"
  zone           = "europe-west4-a"
  tags           = ["nva"]
  can_ip_forward = true
  network_interfaces = [
    {
      network    = module.landing-untrusted-vpc.self_link
      subnetwork = module.landing-untrusted-vpc.subnet_self_links["europe-west4/landing-untrusted-default-ew4"]
      nat        = false
      addresses  = null
    },
    {
      network    = module.landing-trusted-vpc.self_link
      subnetwork = module.landing-trusted-vpc.subnet_self_links["europe-west4/landing-trusted-default-ew4"]
      nat        = false
      addresses  = null
    }
  ]
  boot_disk = {
    image = "projects/debian-cloud/global/images/family/debian-10"
    type  = "pd-balanced"
    size  = 10
  }
  create_template = true
  metadata = {
    startup-script = templatefile(
      "${path.module}/data/nva-startup-script.tftpl",
      {
        dev-default-ew1-cidr           = local.subnets.dev-default-ew1-cidr
        dev-default-ew4-cidr           = local.subnets.dev-default-ew4-cidr
        gateway-trusted                = local.subnets.landing-trusted-default-ew4-gw
        gateway-untrusted              = local.subnets.landing-untrusted-default-ew4-gw
        landing-trusted-other-region   = local.subnets.landing-trusted-default-ew1-cidr
        landing-untrusted-other-region = local.subnets.landing-untrusted-default-ew1-cidr
        onprem-main-cidr               = var.onprem_cidr.main
        prod-default-ew1-cidr          = local.subnets.prod-default-ew1-cidr
        prod-default-ew4-cidr          = local.subnets.prod-default-ew4-cidr
      }
    )
  }
}

module "nva-mig-ew4" {
  source      = "../../../modules/compute-mig"
  project_id  = module.landing-project.project_id
  regional    = true
  location    = "europe-west4"
  name        = "nva-ew4"
  target_size = 2
  auto_healing_policies = {
    health_check      = module.nva-mig-ew4.health_check.self_link
    initial_delay_sec = 30
  }
  health_check_config = {
    type    = "tcp"
    check   = { port = 22 }
    config  = {}
    logging = true
  }
  default_version = {
    instance_template = module.nva-template-ew4.template.self_link
    name              = "default"
  }
}

module "ilb-nva-untrusted-ew4" {
  source        = "../../../modules/net-ilb"
  project_id    = module.landing-project.project_id
  region        = "europe-west4"
  name          = "ilb-nva-untrusted-ew4"
  service_label = var.prefix
  global_access = true
  network       = module.landing-untrusted-vpc.self_link
  subnetwork    = module.landing-untrusted-vpc.subnet_self_links["europe-west4/landing-untrusted-default-ew4"]
  backends = [{
    failover       = false
    group          = module.nva-mig-ew4.group_manager.instance_group
    balancing_mode = "CONNECTION"
  }]
  health_check_config = {
    type = "tcp", check = { port = 22 }, config = {}, logging = false
  }
}

module "ilb-nva-trusted-ew4" {
  source        = "../../../modules/net-ilb"
  project_id    = module.landing-project.project_id
  region        = "europe-west4"
  name          = "ilb-nva-trusted-ew4"
  service_label = var.prefix
  global_access = true
  network       = module.landing-trusted-vpc.self_link
  subnetwork    = module.landing-trusted-vpc.subnet_self_links["europe-west4/landing-trusted-default-ew4"]
  backends = [{
    failover       = false
    group          = module.nva-mig-ew4.group_manager.instance_group
    balancing_mode = "CONNECTION"
  }]
  health_check_config = {
    type = "tcp", check = { port = 22 }, config = {}, logging = false
  }
}
