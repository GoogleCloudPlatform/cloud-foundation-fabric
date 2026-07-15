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

locals {
  psc_endpoint_key = "${var.name}-0"
  region = regex(
    "projects/[^/]+/regions/([^/]+)/subnetworks/[^/]+$",
    var.vpc_config.subnetwork_id
  )[0]
  # shortcut for output references to avoid >79-char lines
  _cluster_region_config = (
    mongodbatlas_advanced_cluster.default.replication_specs[0].region_configs[0]
  )
}

module "addresses" {
  source     = "../../../modules/net-address"
  project_id = var.project_id
  psc_addresses = {
    (local.psc_endpoint_key) = {
      # Avoid the network base address; GCP reserves early host addresses.
      address          = cidrhost(var.vpc_config.psc_cidr_block, 4)
      region           = local.region
      subnet_self_link = var.vpc_config.subnetwork_id
      service_attachment = {
        psc_service_attachment_link = (
          mongodbatlas_privatelink_endpoint.default.service_attachment_names[0]
        )
        global_access = true
      }
    }
  }
}

resource "mongodbatlas_project" "default" {
  name   = var.atlas_config.project_name
  org_id = var.atlas_config.organization_id
}

resource "mongodbatlas_advanced_cluster" "default" {
  project_id             = mongodbatlas_project.default.id
  name                   = var.atlas_config.cluster_name
  cluster_type           = "REPLICASET"
  mongo_db_major_version = var.atlas_config.database_version

  replication_specs = [{
    region_configs = [{
      provider_name = "GCP"
      region_name   = var.atlas_config.region
      priority      = 7
      electable_specs = {
        instance_size = var.atlas_config.instance_size
        node_count    = 3
      }
    }]
  }]
}

moved {
  from = mongodbatlas_cluster.default
  to   = mongodbatlas_advanced_cluster.default
}

resource "mongodbatlas_privatelink_endpoint" "default" {
  project_id           = mongodbatlas_project.default.id
  provider_name        = "GCP"
  region               = var.atlas_config.region
  port_mapping_enabled = true
}

resource "mongodbatlas_privatelink_endpoint_service" "default" {
  project_id                  = mongodbatlas_privatelink_endpoint.default.project_id
  private_link_id             = mongodbatlas_privatelink_endpoint.default.private_link_id
  provider_name               = "GCP"
  endpoint_service_id         = module.addresses.psc[local.psc_endpoint_key].forwarding_rule.name
  private_endpoint_ip_address = module.addresses.psc[local.psc_endpoint_key].address.address
  gcp_project_id              = var.project_id

  # Wait for the GCP PSC forwarding rule before registering it in Atlas.
  depends_on = [module.addresses]
}