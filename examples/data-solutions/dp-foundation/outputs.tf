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

# tfdoc:file:description Output variables.

output "bigquery-datasets" {
  description = "BigQuery datasets."
  value = {
    lnd-bq-0     = module.lnd-bq-0.dataset_id,
    dtl-0-bq-0   = module.dtl-0-bq-0.dataset_id,
    dtl-1-bq-0   = module.dtl-1-bq-0.dataset_id,
    dtl-2-bq-0   = module.dtl-2-bq-0.dataset_id,
    dtl-plg-bq-0 = module.dtl-plg-bq-0.dataset_id,
  }
}

output "gcs-buckets" {
  description = "GCS buckets."
  value = {
    dtl-0-cs-0   = module.dtl-0-cs-0.name,
    dtl-1-cs-0   = module.dtl-1-cs-0.name,
    dtl-2-cs-0   = module.dtl-2-cs-0.name,
    dtl-plg-cs-0 = module.dtl-plg-cs-0.name,
    lnd-cs-0     = module.lnd-cs-0.name,
    lod-cs-df    = module.lod-cs-df-0.name,
    orc-cs-0     = module.orc-cs-0.name,
    trf-cs-df    = module.trf-cs-df-0.name,
  }
}

output "kms_keys" {
  description = "Cloud MKS keys."
  value       = local.service_encryption_keys
}

output "projects" {
  description = "GCP Projects."
  value = {
    project_number = {
      dtl-0-prj   = module.dtl-0-prj.number,
      dtl-1-prj   = module.dtl-1-prj.number,
      dtl-2-prj   = module.dtl-2-prj.number,
      dtl-plg-prj = module.dtl-plg-prj.number,
      exp-prj     = module.exp-prj.number,
      lnd-prj     = module.lnd-prj.number,
      lod-prj     = module.lod-prj.number,
      orc-prj     = module.orc-prj.number,
      trf-prj     = module.trf-prj.number,
    }
    project_id = {
      dtl-0-prj   = module.dtl-0-prj.project_id,
      dtl-1-prj   = module.dtl-1-prj.project_id,
      dtl-2-prj   = module.dtl-2-prj.project_id,
      dtl-plg-prj = module.dtl-plg-prj.project_id,
      exp-prj     = module.exp-prj.project_id,
      lnd-prj     = module.lnd-prj.project_id,
      lod-prj     = module.lod-prj.project_id,
      orc-prj     = module.orc-prj.project_id,
      trf-prj     = module.trf-prj.project_id,
    }
  }
}

output "VPC" {
  description = "VPC networks."
  value = {
    lod-vpc = try(module.lod-vpc[0].name, var.network_config.load)
    orc-vpc = try(module.orc-vpc[0].name, var.network_config.orchestrator)
    trf-vpc = try(module.trf-vpc[0].name, var.network_config.transformation)
  }
}

output "demo_commands" {
  description = "Demo commands."
  value = {
    01 = "gsutil -i ${module.lnd-sa-cs-0.email} cp demo/data/*.csv gs://${module.lnd-cs-0.name}"
    02 = "gsutil -i ${module.orc-sa-cmp-0.email} cp demo/data/*.j* gs://${module.orc-cs-0.name}"
    03 = "gsutil -i ${module.orc-sa-cmp-0.email} cp demo/*.py ${google_composer_environment.orc-cmp-0.config[0].dag_gcs_prefix}/"
    04 = "Open: ${google_composer_environment.orc-cmp-0.config.0.airflow_uri}"
    05 = <<EOT
           bq query --project_id=${module.dtl-2-prj.project_id} --use_legacy_sql=false 'SELECT * FROM `${module.dtl-2-prj.project_id}.${module.dtl-2-bq-0.dataset_id}.customer_purchase` LIMIT 1000'"
         EOT
  }
}
