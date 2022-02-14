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
    land-bq-0     = module.land-bq-0.dataset_id,
    lake-0-bq-0   = module.lake-0-bq-0.dataset_id,
    lake-1-bq-0   = module.lake-1-bq-0.dataset_id,
    lake-2-bq-0   = module.lake-2-bq-0.dataset_id,
    lake-plg-bq-0 = module.lake-plg-bq-0.dataset_id,
  }
}

output "gcs-buckets" {
  description = "GCS buckets."
  value = {
    lake-0-cs-0   = module.lake-0-cs-0.name,
    lake-1-cs-0   = module.lake-1-cs-0.name,
    lake-2-cs-0   = module.lake-2-cs-0.name,
    lake-plg-cs-0 = module.lake-plg-cs-0.name,
    land-cs-0     = module.land-cs-0.name,
    lod-cs-df     = module.load-cs-df-0.name,
    orch-cs-0     = module.orch-cs-0.name,
    transf-cs-df  = module.transf-cs-df-0.name,
  }
}

output "kms_keys" {
  description = "Cloud MKS keys."
  value       = local.service_encryption_keys
}

output "projects" {
  description = "GCP Projects informations."
  value = {
    project_number = {
      lake-0         = module.lake-0-project.number,
      lake-1         = module.lake-1-project.number,
      lake-2         = module.lake-2-project.number,
      lake-plg       = module.lake-plg-project.number,
      exposure       = module.exp-project.number,
      landing        = module.land-project.number,
      load           = module.load-project.number,
      orchestration  = module.orch-project.number,
      transformation = module.transf-project.number,
    }
    project_id = {
      lake-0         = module.lake-0-project.project_id,
      lake-1         = module.lake-1-project.project_id,
      lake-2         = module.lake-2-project.project_id,
      lake-plg       = module.lake-plg-project.project_id,
      exposure       = module.exp-project.project_id,
      landing        = module.land-project.project_id,
      load           = module.load-project.project_id,
      orchestration  = module.orch-project.project_id,
      transformation = module.transf-project.project_id,
    }
  }
}

output "vpc_network" {
  description = "VPC network."
  value = {
    load           = local.load_vpc
    orchestration  = local.orch_vpc
    transformation = local.transf_vpc
  }
}

output "vpc_subnet" {
  description = "VPC subnetworks."
  value = {
    load           = local.load_subnet
    orchestration  = local.orch_subnet
    transformation = local.transf_subnet
  }
}

output "demo_commands" {
  description = "Demo commands."
  value = {
    01 = "gsutil -i ${module.land-sa-cs-0.email} cp demo/data/*.csv gs://${module.land-cs-0.name}"
    02 = "gsutil -i ${module.orch-sa-cmp-0.email} cp demo/data/*.j* gs://${module.orch-cs-0.name}"
    03 = "gsutil -i ${module.orch-sa-cmp-0.email} cp demo/*.py ${google_composer_environment.orch-cmp-0.config[0].dag_gcs_prefix}/"
    04 = "Open ${google_composer_environment.orch-cmp-0.config.0.airflow_uri} and run uploaded DAG."
    05 = <<EOT
           bq query --project_id=${module.lake-2-project.project_id} --use_legacy_sql=false 'SELECT * FROM `${module.lake-2-project.project_id}.${module.lake-2-bq-0.dataset_id}.customer_purchase` LIMIT 1000'"
         EOT
  }
}
