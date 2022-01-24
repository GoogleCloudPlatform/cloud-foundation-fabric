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
        nat        = false
        addresses  = null
      },
      {
        network    = module.landing-trusted-vpc.self_link
        subnetwork = module.landing-trusted-vpc.subnet_self_links["europe-west1/landing-trusted-default-ew1"]
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
    startup-script = "apt update && apt install -y nginx && echo 'Running' > /var/www/index.html"
  }
}

module "nva-mig-ew1" {
  source      = "../../../modules/compute-mig"
  project_id  = module.landing-project.project_id
  regional    = true
  location    = "europe-west1"
  name        = "nva"
  target_size = 2
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
    type = "http", check = { port = 80 }, config = {}, logging = false
  }
}

# europe-west3

module "nva-template-ew3" {
  source         = "../../../modules/compute-vm"
  project_id     = module.landing-project.project_id
  name           = "nva-template"
  zone           = "europe-west3-a"
  tags           = ["nva"]
  can_ip_forward = true
  network_interfaces = [
      {
        network    = module.landing-untrusted-vpc.self_link
        subnetwork = module.landing-untrusted-vpc.subnet_self_links["europe-west3/landing-untrusted-default-ew3"]
        nat        = false
        addresses  = null
      },
      {
        network    = module.landing-trusted-vpc.self_link
        subnetwork = module.landing-trusted-vpc.subnet_self_links["europe-west3/landing-trusted-default-ew3"]
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
    startup-script = "apt update && apt install -y nginx && echo 'Running' > /var/www/index.html"
  }
}

module "nva-mig-ew3" {
  source      = "../../../modules/compute-mig"
  project_id  = module.landing-project.project_id
  regional    = true
  location    = "europe-west3"
  name        = "nva"
  target_size = 2
  default_version = {
    instance_template = module.nva-template-ew3.template.self_link
    name              = "default"
  }
}

module "ilb-nva-untrusted-ew3" {
  source        = "../../../modules/net-ilb"
  project_id    = module.landing-project.project_id
  region        = "europe-west3"
  name          = "ilb-nva-untrusted-ew3"
  service_label = var.prefix
  global_access = true
  network       = module.landing-untrusted-vpc.self_link
  subnetwork    = module.landing-untrusted-vpc.subnet_self_links["europe-west3/landing-untrusted-default-ew3"]
  backends = [{
    failover       = false
    group          = module.nva-mig-ew3.group_manager.instance_group
    balancing_mode = "CONNECTION"
  }]
}

module "ilb-nva-trusted-ew3" {
  source        = "../../../modules/net-ilb"
  project_id    = module.landing-project.project_id
  region        = "europe-west3"
  name          = "ilb-nva-trusted-ew3"
  service_label = var.prefix
  global_access = true
  network       = module.landing-trusted-vpc.self_link
  subnetwork    = module.landing-trusted-vpc.subnet_self_links["europe-west3/landing-trusted-default-ew3"]
  backends = [{
    failover       = false
    group          = module.nva-mig-ew3.group_manager.instance_group
    balancing_mode = "CONNECTION"
  }]
  health_check_config = {
    type = "http", check = { port = 80 }, config = {}, logging = false
  }
}
