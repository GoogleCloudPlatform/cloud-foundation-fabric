/**
 * Copyright 2025 Google LLC
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

# Added this because there is a bug on the provider

provider "google" {
  region = var.instance_region
}

locals {
  hostname    = "${module.addresses.global_addresses.apigee.address}.nip.io"
  environment = "dev"
  envgroup    = "apis"
  environments = {
    (local.environment) = {
      envgroups         = [local.envgroup]
      forward_proxy_uri = "http://${module.apigee.endpoint_attachment_hosts["swp"]}:8080"
    }
  }
  instances = {
    (var.instance_region) = {
      environments = keys(local.environments)
  } }
}


module "project" {
  source = "../../../modules/project"
  name   = var.project_id
  project_reuse = {
    use_data_source = var._testing == null
    attributes      = var._testing
  }
  services = [
    "apigee.googleapis.com",
    "compute.googleapis.com",
    "networksecurity.googleapis.com",
    "networkservices.googleapis.com",
  ]
}

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.id
  name       = "vpc"
  subnets = [
    {
      ip_cidr_range = var.network_config.subnet_ip_cidr_range
      name          = "subnet-${var.instance_region}"
      region        = var.instance_region
    }
  ]
  subnets_psc = [
    {
      ip_cidr_range = var.network_config.subnet_psc_ip_cidr_range
      name          = "subnet-psc-${var.instance_region}"
      region        = var.instance_region
    }
  ]
  subnets_proxy_only = [
    {
      ip_cidr_range = var.network_config.subnet_proxy_only_ip_cidr_range
      name          = "subnet-proxy-only-${var.instance_region}"
      region        = var.instance_region
      active        = true
    }
  ]
}

module "firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.id
  network    = module.vpc.name
  default_rules_config = {
    disabled = true
  }
  ingress_rules = {
    allow-ingress-http = {
      description   = "Allow ingress to http servers."
      targets       = ["http-server"]
      rules         = [{ protocol = "tcp", ports = [80] }]
      source_ranges = [var.network_config.subnet_proxy_only_ip_cidr_range]
    }
  }
}

module "apigee" {
  source     = "../../../modules/apigee"
  project_id = module.project.project_id
  organization = {
    analytics_region    = var.analytics_region
    billing_type        = "EVALUATION"
    runtime_type        = "CLOUD"
    retention           = "MINIMUM"
    disable_vpc_peering = true
  }
  envgroups = {
    "apis" = [local.hostname]
  }
  environments = local.environments
  instances    = local.instances
  endpoint_attachments = {
    swp = {
      region             = var.instance_region
      service_attachment = module.swp.service_attachment
    }
  }
}

module "ext_lb" {
  source     = "../../../modules/net-lb-app-ext"
  name       = "glb"
  project_id = module.project.id
  forwarding_rules_config = {
    "" = {
      address = (
        module.addresses.global_addresses.apigee.address
      )
    }
  }
  protocol            = "HTTPS"
  use_classic_version = false
  backend_service_configs = {
    default = {
      backends      = [for k, v in module.apigee.instances : { backend = "neg-${k}" }]
      protocol      = "HTTPS"
      health_checks = []
    }
  }
  neg_configs = {
    for k, v in module.apigee.instances :
    "neg-${k}" => { psc = {
      region         = k
      target_service = v.service_attachment
      network        = module.vpc.self_link
      subnetwork     = module.vpc.subnets_psc["${var.instance_region}/subnet-psc-${var.instance_region}"].self_link
      }
    }
  }
  ssl_certificates = {
    managed_configs = {
      default = {
        domains = [local.hostname]
      }
    }
  }
}

module "swp" {
  source     = "../../../modules/net-swp"
  project_id = module.project.id
  region     = var.instance_region
  name       = "gateway"
  network    = module.vpc.id
  subnetwork = module.vpc.subnet_self_links["${var.instance_region}/subnet-${var.instance_region}"]
  gateway_config = {
    addresses = [module.addresses.internal_addresses["gateway"].address]
    ports     = [8080]
  }
  service_attachment = {
    nat_subnets          = [module.vpc.subnets_psc["${var.instance_region}/subnet-psc-${var.instance_region}"].self_link]
    automatic_connection = true
  }
  policy_rules = {
    allowed-hosts = {
      priority        = 1000
      allow           = true
      session_matcher = "host() == '${module.nginx_vm.internal_ip}'"
    }
  }
}

module "addresses" {
  source     = "../../../modules/net-address"
  project_id = module.project.project_id
  internal_addresses = {
    gateway = {
      region     = var.instance_region
      subnetwork = module.vpc.subnet_self_links["${var.instance_region}/subnet-${var.instance_region}"]
    }
  }
  global_addresses = {
    apigee = {}
  }
}

module "nginx_vm" {
  source     = "../../../modules/compute-vm"
  project_id = module.project.project_id
  zone       = "${var.instance_region}-b"
  name       = "nginx"
  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.instance_region}/subnet-${var.instance_region}"]
  }]
  metadata = {
    startup-script = <<-EOF
      #! /bin/bash
      apt-get update
      apt-get install -y nginx
    EOF
  }
  service_account = {
    auto_create = true
  }
  tags = [
    "http-server"
  ]
}

resource "local_file" "target_endpoint_file" {
  content = templatefile("${path.module}/templates/targets/default.xml.tpl", {
    ip_address = module.nginx_vm.internal_ip
  })
  filename        = "${path.module}/bundle/apiproxy/targets/default.xml"
  file_permission = "0644"
}

# tflint-ignore: terraform_unused_declarations
data "archive_file" "bundle" {
  type        = "zip"
  source_dir  = "${path.module}/bundle"
  output_path = "${path.module}/bundle.zip"
  depends_on = [
    local_file.target_endpoint_file
  ]
}

resource "local_file" "deploy_apiproxy_file" {
  content = templatefile("${path.module}/templates/deploy-apiproxy.sh.tpl", {
    organization = module.apigee.org_name
    environment  = local.environment
  })
  filename        = "${path.module}/deploy-apiproxy.sh"
  file_permission = "0755"
}

module "nat" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  region         = var.instance_region
  name           = "nat-${var.instance_region}"
  router_network = module.vpc.self_link
}
