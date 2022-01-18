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

###############################################################################
#                                Composer                                     #
###############################################################################

module "orc-sa-cmp-0" {
  source     = "../../../modules/iam-service-account"
  project_id = module.orc-prj.project_id
  name       = "cmp-0"
  prefix     = local.prefix_orc
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers
    ],
    "roles/iam.serviceAccountUser" = [
      module.orc-sa-cmp-0.iam_email,
    ]
  }
}

resource "google_composer_environment" "orc-cmp-0" {
  name     = "${local.prefix_orc}-cmp-0"
  region   = var.composer_config.region
  provider = google-beta
  project  = module.orc-prj.project_id
  config {
    node_count = 3
    node_config {
      zone            = "${var.composer_config.region}-b"
      service_account = module.orc-sa-cmp-0.email
      network         = module.orc-vpc[0].self_link
      subnetwork      = module.orc-vpc[0].subnet_self_links["${var.composer_config.region}/subnet"]
      tags            = ["composer-worker", "http-server", "https-server"]
      ip_allocation_policy {
        use_ip_aliases                = "true"
        cluster_secondary_range_name  = "pods"
        services_secondary_range_name = "services"
      }
    }
    software_config {
      env_variables = {
        DTL_L0_BQ_DATASET  = module.dtl-0-bq-0.dataset_id
        DTL_L1_BQ_DATASET  = module.dtl-1-bq-0.dataset_id
        DTL_L2_BQ_DATASET  = module.dtl-2-bq-0.dataset_id
        DTL_EXP_BQ_DATASET = module.dtl-exp-bq-0.dataset_id
        DTL_L0_GCS         = module.dtl-0-cs-0.url
        DTL_L1_GCS         = module.dtl-1-cs-0.url
        DTL_L2_GCS         = module.dtl-2-cs-0.url
        DTL_EXP_GCS        = module.dtl-exp-cs-0.url
        LND_GCS            = module.lnd-cs-0.url
        LND_BQ             = module.lnd-bq-0.dataset_id
        LND_PS             = module.lnd-ps-0.id
        LOD_GCS_STAGING    = module.lod-cs-df-0.url
        TRF_GCS_STAGING    = module.trf-cs-df-0.url
        GCP_REGION         = var.composer_config.region
        NET_VPC            = module.orc-vpc[0].self_link
        NET_SUBNET         = module.orc-vpc[0].subnet_self_links["${var.composer_config.region}/subnet"]
        DTL_L0_PRJ         = module.dtl-0-prj.project_id
        DTL_L1_PRJ         = module.dtl-1-prj.project_id
        DTL_L2_PRJ         = module.dtl-2-prj.project_id
        LND_PRJ            = module.lnd-prj.project_id
        LOD_PRJ            = module.lod-prj.project_id
        ORC_PRJ            = module.orc-prj.project_id
        TRF_PRJ            = module.trf-prj.project_id
        LOD_SA_DF          = module.lod-sa-df-0.email
        TRF_SA_DF          = module.lod-sa-df-0.email
      }
    }
    private_environment_config {
      enable_private_endpoint    = "true"
      master_ipv4_cidr_block     = var.composer_config.ip_range_gke_master
      cloud_sql_ipv4_cidr_block  = var.composer_config.ip_range_cloudsql
      web_server_ipv4_cidr_block = var.composer_config.ip_range_web_server
    }

    dynamic "encryption_config" {
      for_each = can(module.kms[0].keys.key-cmp.id) ? { 1 = 1 } : {}
      content {
        kms_key_name = var.cmek_encryption ? try(module.kms[0].keys.key-cmp.id, null) : null
      }
    }

    # web_server_network_access_control {
    #   allowed_ip_range {
    #     value       = "172.16.0.0/12"
    #     description = "Allowed ip range"
    #   }
    # }
  }
  depends_on = [
    module.dtl-0-bq-0,
    module.dtl-1-bq-0,
    module.dtl-2-bq-0,
    module.dtl-exp-bq-0,
    module.dtl-0-cs-0,
    module.dtl-1-cs-0,
    module.dtl-2-cs-0,
    module.dtl-exp-cs-0,
    module.lnd-cs-0,
    module.lnd-bq-0,
    module.lnd-ps-0,
    module.lod-cs-df-0,
    module.trf-cs-df-0,
    module.orc-vpc,
    module.orc-vpc,
    module.dtl-0-prj,
    module.dtl-1-prj,
    module.dtl-2-prj,
    module.lnd-prj,
    module.lod-prj,
    module.orc-prj,
    module.trf-prj,
    module.lod-sa-df-0,
    module.lod-sa-df-0,
  ]
}
