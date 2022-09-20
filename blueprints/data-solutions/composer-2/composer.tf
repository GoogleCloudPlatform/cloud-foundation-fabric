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

module "comp-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.project.project_id
  prefix       = var.prefix
  name         = "cmp"
  display_name = "Composer service account"
}

resource "google_composer_environment" "env" {
  name    = "${var.prefix}-composer"
  project = module.project.project_id
  region  = var.region
  config {
    software_config {
      image_version = var.composer_config.image_version
    }
    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
      }
      worker {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        min_count  = 1
        max_count  = 3
      }
    }
    environment_size = var.composer_config.environment_size

    node_config {
      network              = local.orch_vpc
      subnetwork           = local.orch_subnet
      service_account      = module.comp-sa.email
      enable_ip_masq_agent = "true"
      tags                 = ["composer-worker"]
      ip_allocation_policy {
        cluster_secondary_range_name = try(
          var.network_config.composer_secondary_ranges.pods, "pods"
        )
        services_secondary_range_name = try(
          var.network_config.composer_secondary_ranges.services, "services"
        )
      }
    }
    private_environment_config {
      enable_private_endpoint = "true"
      cloud_sql_ipv4_cidr_block = try(
        var.network_config.composer_ip_ranges.cloudsql, "10.20.10.0/24"
      )
      master_ipv4_cidr_block = try(
        var.network_config.composer_ip_ranges.gke_master, "10.20.11.0/28"
      )
    }
    dynamic "encryption_config" {
      for_each = (
        try(var.service_encryption_keys[var.region], null) != null
        ? { 1 = 1 }
        : {}
      )
      content {
        kms_key_name = try(var.service_encryption_keys[var.region], null)
      }
    }
  }
  depends_on = [
    google_project_iam_member.shared_vpc,
    module.project
  ]
}
