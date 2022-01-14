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

output "bq_tables" {
  description = "Bigquery Tables."
  value       = module.bigquery-dataset.table_ids
}

output "buckets" {
  description = "GCS Bucket Cloud KMS crypto keys."
  value = {
    data   = module.gcs-data.name
    df-tmp = module.gcs-df-tmp.name
  }
}

output "data_ingestion_command" {
  value = <<-EOF
    python data_ingestion.py \
      --runner=DataflowRunner \
      --max_num_workers=10 \
      --autoscaling_algorithm=THROUGHPUT_BASED \
      --region=${var.region} \
      --staging_location=${module.gcs-df-tmp.url} \
      --temp_location=${module.gcs-df-tmp.url}/ \
      --project=${var.project_id} \
      --input=${module.gcs-data.url}/### FILE NAME ###.csv \
      --output=${module.bigquery-dataset.dataset_id}.${module.bigquery-dataset.table_ids.df_import} \
      --service_account_email=${module.service-account-df.email} \
      --network=${module.vpc.name} \
      --subnetwork=${local.subnet_name} \
      --dataflow_kms_key=${module.kms.key_ids.key-df} \
      --no_use_public_ips
  EOF
}

output "project_id" {
  description = "Project id."
  value       = module.project.project_id
}

output "vm" {
  description = "GCE VM."
  value = {
    name    = module.vm.instance.name
    address = module.vm.internal_ip
  }
}
