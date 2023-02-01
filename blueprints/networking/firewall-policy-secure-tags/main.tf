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
  prefix      = var.prefix == null ? "" : "${var.prefix}-"
  region-zone = "${var.region}-${var.zone}"
}

module "organization" {
  source          = "../../../modules/organization"
  organization_id = var.organization_id
  network_tags = {
    net-environment = {
      description = "A network tag representing the security profiles."
      network     = "${module.project.project_id}/${module.vpc.name}"
      iam = {
        "roles/resourcemanager.tagAdmin" = ["user:${var.identities.admin}"]
      }
      values = {
        vpc1 = {
          description = "Tag key associated to vpc1"
          iam = {
            "roles/resourcemanager.tagUser" = ["user:${var.identities.vpc1}"]
          }
        }
        vpc2 = {
          description = "Tag key associated to vpc2"
          iam = {
            "roles/resourcemanager.tagUser" = ["user:${var.identities.vpc2}"]
          }
        }
      }
    }
  }
}

module "project" {
  source          = "../../../modules/project"
  project_create  = var.project_create
  billing_account = try(var.project_config.billing_account, null)
  parent          = try(var.project_config.parent, null)
  name            = try(var.project_config.id, null)
  services = [
    "compute.googleapis.com"
  ]
}

module "vpc1" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.prefix}-vpc1"
  subnets = [
    {
      name          = "vpc1-main"
      ip_cidr_range = var.network_config.vpc1.subnet_cidr
      region        = var.region
    }
  ]
}

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.prefix}-vpc2"
  subnets = [
    {
      name          = "vpc2-main"
      ip_cidr_range = var.network_config.vpc2.subnet_cidr
      region        = var.region
    }
  ]
}

module "dst" {
  source                 = "../../../modules/compute-vm"
  project_id             = module.project.project_id
  zone                   = local.region-zone
  name                   = "${local.prefix}dst"
  instance_type          = var.instance_type
  service_account_create = true
  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/vpc1-main"]
  }]
  iam = {
    "roles/resourcemanager.tagUser" = ["user:${var.identities.dst}"]
  }
  tag_bindings = {
    net-env = module.organization.network_tag_values["vpc1/dst"].namespaced_name
  }
}

module "prod_vm" {
  source                 = "../../../modules/compute-vm"
  project_id             = module.project.project_id
  zone                   = local.region-zone
  name                   = "${var.prefix}-prod-vm"
  instance_type          = var.instance_type
  service_account_create = true
  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/main"]
  }]
  iam = {
    "roles/resourcemanager.tagUser" = ["user:${var.identities.prod}"]
  }
  tag_bindings = {
    net-env = module.organization.network_tag_values["net-environment/prod"].namespaced_name
  }
}

# Create network firewall policies and rules

resource "google_compute_network_firewall_policy" "fw_policy" {
  name        = "${var.prefix}-fw-policy"
  project     = module.project.project_id
  description = "Example network firewall policy."
}

resource "google_compute_network_firewall_policy_association" "fw_association" {
  name              = "${var.prefix}-fw-policy-association"
  attachment_target = module.vpc.self_link
  firewall_policy   = google_compute_network_firewall_policy.fw_policy.name
  project           = module.project.project_id
}


resource "google_compute_network_firewall_policy_rule" "allow_icmp_prod_dev" {
  project         = module.project.project_id
  description     = "Allow icmp from prod to dev."
  priority        = 501
  firewall_policy = google_compute_network_firewall_policy.fw_policy.id
  enable_logging  = true
  action          = "allow"
  direction       = "INGRESS"

  target_secure_tags {
    name = module.organization.network_tag_values["net-environment/dev"].id
  }

  match {
    src_secure_tags {
      name = module.organization.network_tag_values["net-environment/prod"].id
    }
    layer4_configs {
      ip_protocol = "icmp"
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "allow_ssh_prod_dev" {
  project         = module.project.project_id
  description     = "Allow ssh from prod to dev."
  priority        = 502
  firewall_policy = google_compute_network_firewall_policy.fw_policy.id
  enable_logging  = true
  action          = "allow"
  direction       = "INGRESS"

  target_secure_tags {
    name = module.organization.network_tag_values["net-environment/dev"].id
  }

  match {
    src_secure_tags {
      name = module.organization.network_tag_values["net-environment/prod"].id
    }
    layer4_configs {
      ip_protocol = "tcp"
      ports       = [22]
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "allow_iap" {
  project         = module.project.project_id
  description     = "Allow ssh from prod to dev."
  priority        = 503
  firewall_policy = google_compute_network_firewall_policy.fw_policy.id
  enable_logging  = true
  action          = "allow"
  direction       = "INGRESS"

  target_secure_tags {
    name = module.organization.network_tag_values["net-environment/dev"].id
  }

  target_secure_tags {
    name = module.organization.network_tag_values["net-environment/prod"].id
  }

  match {
    src_secure_tags {
      name = module.organization.network_tag_values["net-environment/prod"].id
    }
    layer4_configs {
      ip_protocol = "tcp"
      ports       = [22]
    }
  }
}
