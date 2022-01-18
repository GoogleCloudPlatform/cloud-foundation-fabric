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

output "bigquery-datasets" {
  description = "BigQuery datasets."
  value = {
    lnd-bq-0     = module.lnd-bq-0.dataset_id,
    dtl-0-bq-0   = module.dtl-0-bq-0.dataset_id,
    dtl-1-bq-0   = module.dtl-1-bq-0.dataset_id,
    dtl-2-bq-0   = module.dtl-2-bq-0.dataset_id,
    dtl-exp-bq-0 = module.dtl-exp-bq-0.dataset_id,
  }
}

output "gcs-buckets" {
  description = "GCS buckets."
  value = {
    dtl-0-cs-0   = module.dtl-0-cs-0.name,
    dtl-1-cs-0   = module.dtl-1-cs-0.name,
    dtl-2-cs-0   = module.dtl-2-cs-0.name,
    dtl-exp-cs-0 = module.dtl-exp-cs-0.name,
    lnd-cs-0     = module.lnd-cs-0.name,
    lod-cs-df    = module.lod-cs-df-0.name,
    orc-cs-0     = module.orc-cs-0.name,
    trf-cs-df    = module.trf-cs-df-0.name,
  }
}

output "projects" {
  description = "GCP Projects."
  value = {
    lnd-prj     = module.lnd-prj.project_id,
    lod-prj     = module.lod-prj.project_id,
    orc-prj     = module.orc-prj.project_id,
    trf-prj     = module.trf-prj.project_id,
    dtl-0-prj   = module.dtl-0-prj.project_id,
    dtl-1-prj   = module.dtl-1-prj.project_id,
    dtl-2-prj   = module.dtl-2-prj.project_id,
    dtl-exp-prj = module.dtl-exp-prj.project_id,
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

output "ZZZ_demo_commands" {
  description = "Demo commands"
  value = {
    01 = "gsutil -i ${module.lod-sa-df-0.email} cp demo/data/*.csv gs://${module.lnd-cs-0.name}"
    02 = "gsutil cp demo/data/*.j* gs://${module.orc-cs-0.name}"
    03 = "gsutil cp demo/gcs2bq.py ${google_composer_environment.orc-cmp-0.config[0].dag_gcs_prefix}/"
    04 = "bq mk --table --description 'Customers table' ${module.dtl-0-prj.project_id}:${module.dtl-0-bq-0.dataset_id}.customers demo/data/customers.json"
    05 = "bq mk --table --description 'Purchases table' ${module.dtl-0-prj.project_id}:${module.dtl-0-bq-0.dataset_id}.purchases demo/data/purchases.json"
    06 = "bq mk --table --description 'Customer_Purchase table' ${module.dtl-1-prj.project_id}:${module.dtl-1-bq-0.dataset_id}.customers demo/data/customer_purchase.json"
  }
}
