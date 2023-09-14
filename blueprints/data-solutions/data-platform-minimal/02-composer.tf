# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Cloud Composer resources.

locals {
  _env_variables = {
    BQ_LOCATION        = var.location
    CURATED_BQ_DATASET = module.cur-bq-0.dataset_id
    CURATED_GCS        = module.cur-cs-0.url
    CURATED_PRJ        = module.cur-project.project_id
    DP_KMS_KEY         = var.service_encryption_keys.compute
    DP_REGION          = var.region
    LAND_PRJ           = module.land-project.project_id
    LAND_GCS           = module.land-cs-0.url
    PHS_CLUSTER_NAME   = try(module.processing-dp-historyserver[0].name, "")
    PROCESSING_GCS     = module.processing-cs-0.url
    PROCESSING_PRJ     = module.processing-project.project_id
    PROCESSING_SA      = module.processing-sa-0.email
    PROCESSING_SUBNET  = local.processing_subnet
    PROCESSING_VPC     = local.processing_vpc
  }
  env_variables = {
    for k, v in merge(
      var.composer_config.software_config.env_variables, local._env_variables
    ) : "AIRFLOW_VAR_${k}" => v
  }
}

module "processing-sa-cmp-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.processing-project.project_id
  prefix       = var.prefix
  name         = "prc-cmp-0"
  display_name = "Data platform Composer service account"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [local.groups_iam.data-engineers]
    "roles/iam.serviceAccountUser"         = [module.processing-sa-cmp-0.iam_email]
  }
}

resource "google_composer_environment" "processing-cmp-0" {
  count    = var.enable_services.composer == true ? 1 : 0
  provider = google-beta
  project  = module.processing-project.project_id
  name     = "${var.prefix}-prc-cmp-0"
  region   = var.region
  config {
    software_config {
      airflow_config_overrides = var.composer_config.software_config.airflow_config_overrides
      pypi_packages            = var.composer_config.software_config.pypi_packages
      env_variables            = local.env_variables
      image_version            = var.composer_config.software_config.image_version
      cloud_data_lineage_integration {
        enabled = var.composer_config.software_config.cloud_data_lineage_integration
      }
    }
    workloads_config {
      scheduler {
        cpu        = var.composer_config.workloads_config.scheduler.cpu
        memory_gb  = var.composer_config.workloads_config.scheduler.memory_gb
        storage_gb = var.composer_config.workloads_config.scheduler.storage_gb
        count      = var.composer_config.workloads_config.scheduler.count
      }
      web_server {
        cpu        = var.composer_config.workloads_config.web_server.cpu
        memory_gb  = var.composer_config.workloads_config.web_server.memory_gb
        storage_gb = var.composer_config.workloads_config.web_server.storage_gb
      }
      worker {
        cpu        = var.composer_config.workloads_config.worker.cpu
        memory_gb  = var.composer_config.workloads_config.worker.memory_gb
        storage_gb = var.composer_config.workloads_config.worker.storage_gb
        min_count  = var.composer_config.workloads_config.worker.min_count
        max_count  = var.composer_config.workloads_config.worker.max_count
      }
    }

    environment_size = var.composer_config.environment_size

    node_config {
      network              = local.processing_vpc
      subnetwork           = local.processing_subnet
      service_account      = module.processing-sa-cmp-0.email
      enable_ip_masq_agent = true
      tags                 = ["composer-worker"]
      ip_allocation_policy {
        cluster_secondary_range_name  = var.network_config.composer_ip_ranges.pods_range_name
        services_secondary_range_name = var.network_config.composer_ip_ranges.services_range_name
      }
    }
    private_environment_config {
      enable_private_endpoint              = "true"
      cloud_sql_ipv4_cidr_block            = var.network_config.composer_ip_ranges.cloud_sql
      master_ipv4_cidr_block               = var.network_config.composer_ip_ranges.gke_master
      cloud_composer_connection_subnetwork = var.network_config.composer_ip_ranges.connection_subnetwork
    }
    dynamic "encryption_config" {
      for_each = (
        var.service_encryption_keys.composer != null
        ? { 1 = 1 }
        : {}
      )
      content {
        kms_key_name = var.service_encryption_keys.composer
      }
    }
    web_server_network_access_control {
      dynamic "allowed_ip_range" {
        for_each = var.composer_config.web_server_access_control
        content {
          value       = allowed_ip_range.key
          description = allowed_ip_range.value
        }
      }
    }
  }
  depends_on = [
    module.processing-project
  ]
}
