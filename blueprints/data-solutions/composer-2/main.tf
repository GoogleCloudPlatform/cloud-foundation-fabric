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

locals {
  # add Roles on Service Identities service account as per documentation
  # https://cloud.google.com/composer/docs/composer-2/configure-shared-vpc#edit_permissions_for_the_google_apis_service_account
  _shared_vpc_bindings = {
    "roles/compute.networkUser" = [
      "prj-cloudservices", "prj-robot-gke"
    ]
    "roles/composer.sharedVpcAgent" = [
      "prj-robot-cs"
    ]
    "roles/container.hostServiceAgentUser" = [
      "prj-robot-gke"
    ]
  }
  orch_subnet = (
    local.use_shared_vpc
    ? var.network_config.subnet_self_link
    : values(module.vpc[0].subnet_self_links)[0]
  )
  orch_vpc = (
    local.use_shared_vpc
    ? var.network_config.network_self_link
    : module.vpc[0].self_link
  )
  # reassemble in a format suitable for for_each
  shared_vpc_bindings_map = {
    for binding in flatten([
      for role, members in local._shared_vpc_bindings : [
        for member in members : { role = role, member = member }
      ]
    ]) : "${binding.role}-${binding.member}" => binding
  }
  shared_vpc_project = try(var.network_config.host_project, null)
  shared_vpc_role_members = {
    prj-cloudservices = (
      module.project.service_agents.cloudservices.iam_email
    )
    prj-robot-gke = (
      module.project.service_agents.container-engine.iam_email
    )
    prj-robot-cs = (
      module.project.service_agents.composer.iam_email
    )
  }
  use_shared_vpc = var.network_config != null
  vpc_self_link = (
    local.use_shared_vpc
    ? var.network_config.network_self_link
    : module.vpc[0].self_link
  )
}

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
  iam_bindings_additive = merge(
    {
      composer_worker = {
        member = module.comp-sa.iam_email
        role   = "roles/composer.worker"
      },
      composer_service_agent = {
        member = module.project.service_agents.composer.iam_email
        role   = "roles/composer.ServiceAgentV2Ext"
      }
    },
    {
      for k, v in var.iam_bindings_additive : "${k}:${v}" => {
        member = v
        role   = k
      }
    }
  )
  services = [
    "artifactregistry.googleapis.com",
    "cloudkms.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "iap.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com",
  ]
  shared_vpc_service_config = local.shared_vpc_project == null ? null : {
    attach       = true
    host_project = local.shared_vpc_project
  }
  service_encryption_key_ids = {
    "composer.googleapis.com" = compact([lookup(var.service_encryption_keys, var.region, null)])
  }
}

module "vpc" {
  source     = "../../../modules/net-vpc"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.project.project_id
  name       = "vpc"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/20"
      name          = "subnet"
      region        = var.region
      secondary_ip_ranges = {
        pods     = "10.10.8.0/22"
        services = "10.10.12.0/24"
      }
    }
  ]
}

# No explicit firewall rules set, created automatically by GKE autopilot

module "nat" {
  source         = "../../../modules/net-cloudnat"
  count          = local.use_shared_vpc ? 0 : 1
  project_id     = module.project.project_id
  region         = var.region
  name           = "${var.prefix}-default"
  router_network = module.vpc[0].name
}

resource "google_project_iam_member" "shared_vpc" {
  for_each = local.use_shared_vpc ? local.shared_vpc_bindings_map : {}
  project  = var.network_config.host_project
  role     = each.value.role
  member   = lookup(local.shared_vpc_role_members, each.value.member)
}
