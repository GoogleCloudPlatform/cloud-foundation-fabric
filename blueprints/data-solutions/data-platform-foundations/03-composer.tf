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

# tfdoc:file:description Orchestration Cloud Composer definition.

locals {
  _env_variables = {
    BQ_LOCATION                 = var.location
    DATA_CAT_TAGS               = try(jsonencode(module.common-datacatalog.tags), "{}")
    DF_KMS_KEY                  = try(var.service_encryption_keys.dataflow, "")
    DRP_PRJ                     = module.drop-project.project_id
    DRP_BQ                      = module.drop-bq-0.dataset_id
    DRP_GCS                     = module.drop-cs-0.url
    DRP_PS                      = module.drop-ps-0.id
    DWH_LAND_PRJ                = module.dwh-lnd-project.project_id
    DWH_LAND_BQ_DATASET         = module.dwh-lnd-bq-0.dataset_id
    DWH_LAND_GCS                = module.dwh-lnd-cs-0.url
    DWH_CURATED_PRJ             = module.dwh-cur-project.project_id
    DWH_CURATED_BQ_DATASET      = module.dwh-cur-bq-0.dataset_id
    DWH_CURATED_GCS             = module.dwh-cur-cs-0.url
    DWH_CONFIDENTIAL_PRJ        = module.dwh-conf-project.project_id
    DWH_CONFIDENTIAL_BQ_DATASET = module.dwh-conf-bq-0.dataset_id
    DWH_CONFIDENTIAL_GCS        = module.dwh-conf-cs-0.url
    GCP_REGION                  = var.region
    LOD_PRJ                     = module.load-project.project_id
    LOD_GCS_STAGING             = module.load-cs-df-0.url
    LOD_NET_VPC                 = local.load_vpc
    LOD_NET_SUBNET              = local.load_subnet
    LOD_SA_DF                   = module.load-sa-df-0.email
    ORC_PRJ                     = module.orch-project.project_id
    ORC_GCS                     = module.orch-cs-0.url
    ORC_GCS_TMP_DF              = module.orch-cs-df-template.url
    TRF_PRJ                     = module.transf-project.project_id
    TRF_GCS_STAGING             = module.transf-cs-df-0.url
    TRF_NET_VPC                 = local.transf_vpc
    TRF_NET_SUBNET              = local.transf_subnet
    TRF_SA_DF                   = module.transf-sa-df-0.email
    TRF_SA_BQ                   = module.transf-sa-bq-0.email
  }
  env_variables = {
    for k, v in merge(
      try(var.composer_config.software_config.env_variables, null),
      local._env_variables
    ) : "AIRFLOW_VAR_${k}" => v
  }
}
module "orch-sa-cmp-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.orch-project.project_id
  prefix       = var.prefix
  name         = "orc-cmp-0"
  display_name = "Data platform Composer service account"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [local.groups_iam.data-engineers]
    "roles/iam.serviceAccountUser"         = [module.orch-sa-cmp-0.iam_email]
  }
}

resource "google_composer_environment" "orch-cmp-0" {
  count    = var.composer_config.disable_deployment == true ? 0 : 1
  provider = google-beta
  project  = module.orch-project.project_id
  name     = "${var.prefix}-orc-cmp-0"
  region   = var.region
  config {
    software_config {
      airflow_config_overrides = try(var.composer_config.software_config.airflow_config_overrides, null)
      pypi_packages            = try(var.composer_config.software_config.pypi_packages, null)
      env_variables            = local.env_variables
      image_version            = try(var.composer_config.software_config.image_version, null)
      cloud_data_lineage_integration {
        enabled = var.composer_config.software_config.cloud_data_lineage_integration
      }
    }
    dynamic "workloads_config" {
      for_each = (try(var.composer_config.workloads_config, null) != null ? { 1 = 1 } : {})

      content {
        scheduler {
          cpu        = try(var.composer_config.workloads_config.scheduler.cpu, null)
          memory_gb  = try(var.composer_config.workloads_config.scheduler.memory_gb, null)
          storage_gb = try(var.composer_config.workloads_config.scheduler.storage_gb, null)
          count      = try(var.composer_config.workloads_config.scheduler.count, null)
        }
        web_server {
          cpu        = try(var.composer_config.workloads_config.web_server.cpu, null)
          memory_gb  = try(var.composer_config.workloads_config.web_server.memory_gb, null)
          storage_gb = try(var.composer_config.workloads_config.web_server.storage_gb, null)
        }
        worker {
          cpu        = try(var.composer_config.workloads_config.worker.cpu, null)
          memory_gb  = try(var.composer_config.workloads_config.worker.memory_gb, null)
          storage_gb = try(var.composer_config.workloads_config.worker.storage_gb, null)
          min_count  = try(var.composer_config.workloads_config.worker.min_count, null)
          max_count  = try(var.composer_config.workloads_config.worker.max_count, null)
        }
      }
    }

    environment_size = var.composer_config.environment_size

    node_config {
      network              = local.orch_vpc
      subnetwork           = local.orch_subnet
      service_account      = module.orch-sa-cmp-0.email
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
    module.orch-project
  ]
}
