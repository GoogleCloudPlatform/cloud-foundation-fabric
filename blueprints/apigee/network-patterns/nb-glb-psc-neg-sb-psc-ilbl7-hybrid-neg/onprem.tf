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

module "onprem_project" {
  source          = "../../../../modules/project"
  billing_account = var.billing_account_id
  parent          = var.parent
  name            = var.onprem_project_id
  services = [
    "compute.googleapis.com"
  ]
}

module "onprem_vpc" {
  source     = "../../../../modules/net-vpc"
  project_id = module.onprem_project.project_id
  name       = "vpc"
  subnets_proxy_only = [
    {
      ip_cidr_range = var.onprem_proxy_only_subnet_ip_cidr_range
      name          = "regional-proxy"
      region        = var.region
      active        = true
    }
  ]
  subnets = [
    {
      ip_cidr_range = var.onprem_subnet_ip_cidr_range
      name          = "subnet"
      region        = var.region
    }
  ]
}

module "firewall" {
  source     = "../../../../modules/net-vpc-firewall"
  project_id = module.onprem_project.project_id
  network    = module.onprem_vpc.network.name
  default_rules_config = {
    disabled = true
  }
  ingress_rules = {
    fw-allow-health-check = {
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      targets       = ["http-server"]
      rules         = [{ protocol = "tcp", ports = ["80"] }]
    }
    fw-allow-proxies = {
      source_ranges = [var.onprem_proxy_only_subnet_ip_cidr_range]
      targets       = ["http-server"]
      rules         = [{ protocol = "tcp", ports = ["80"] }]
    }
  }
}

module "cos-nginx" {
  source = "../../../../modules/cloud-config-container/nginx"
}

module "instance_template" {
  source     = "../../../../modules/compute-vm"
  project_id = module.onprem_project.project_id
  name       = "nginx-template"
  zone       = var.zone
  tags       = ["http-server", "ssh"]
  network_interfaces = [{
    network    = module.onprem_vpc.self_link
    subnetwork = module.onprem_vpc.subnet_self_links["${var.region}/subnet"]
    nat        = false
    addresses  = null
  }]
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }
  create_template = true
  metadata = {
    user-data = module.cos-nginx.cloud_config
  }
}

module "mig" {
  source            = "../../../../modules/compute-mig"
  project_id        = module.onprem_project.project_id
  location          = var.region
  name              = "mig"
  target_size       = 2
  instance_template = module.instance_template.template.self_link
  named_ports = {
    http = 80
  }
  health_check_config = {
    check_interval_sec = 1
    enable_logging     = true
    healthy_threshold  = 1
    http = {
      port_name = "http"
    }
    timeout_sec         = 1
    unhealthy_threshold = 1
  }
}

module "onprem_ilb_l7" {
  source     = "../../../../modules/net-lb-app-int"
  name       = "ilb"
  project_id = module.onprem_project.project_id
  region     = var.region
  backend_service_configs = {
    default = {
      port_name = "http"
      backends = [{
        group = module.mig.group_manager.instance_group
      }]
    }
  }
  health_check_configs = {
    default = {
      check_interval_sec = 1
      enable_logging     = true
      healthy_threshold  = 1
      http = {
        port_name          = "http"
        port_specification = "USE_NAMED_PORT"
        request_path       = "/"
      }
      timeout_sec         = 1
      unhealthy_threshold = 1
    }
  }
  vpc_config = {
    network    = module.onprem_vpc.self_link
    subnetwork = module.onprem_vpc.subnet_self_links["${var.region}/subnet"]
  }
  depends_on = [
    module.onprem_vpc.subnets_proxy_only
  ]
}
