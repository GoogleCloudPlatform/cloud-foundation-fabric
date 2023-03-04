# # Copyright 2022 Google LLC
# #
# # Licensed under the Apache License, Version 2.0 (the "License");
# # you may not use this file except in compliance with the License.
# # You may obtain a copy of the License at
# #
# #     https://www.apache.org/licenses/LICENSE-2.0
# #
# # Unless required by applicable law or agreed to in writing, software
# # distributed under the License is distributed on an "AS IS" BASIS,
# # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# # See the License for the specific language governing permissions and
# # limitations under the License.

# tfdoc:file:description Output variables.
output "bigquery-datasets" {
  description = "BigQuery datasets."
  value = {
    curated = module.cur-bq-0.dataset_id,
  }
}

output "demo_commands" {
  description = "Demo commands. Relevant only if Composer is deployed."
  value = {
    01 = "gsutil -i ${module.processing-sa-cmp-0.email} cp demo/pyspark_sort.py gs://${module.processing-cs-0.name}"
    02 = try("gsutil -i ${module.processing-sa-cmp-0.email} cp demo/orchestrate_pyspark.py ${google_composer_environment.processing-cmp-0[0].config[0].dag_gcs_prefix}/", "Composer not deployed")
    #     04 = <<EOT
    #     gcloud builds submit \
    #       --config=./demo/dataflow-csv2bq/cloudbuild.yaml \
    #       --project=${module.orch-project.project_id} \
    #       --region="${var.region}" \
    #       --gcs-log-dir=gs://${module.orch-cs-build-staging.name}/log \
    #       --gcs-source-staging-dir=gs://${module.orch-cs-build-staging.name}/staging \
    #       --impersonate-service-account=${module.orch-sa-df-build.email} \
    #       --substitutions=_TEMPLATE_IMAGE="${local.orch_docker_path}/csv2bq:latest",_TEMPLATE_PATH="gs://${module.orch-cs-df-template.name}/csv2bq.json",_DOCKER_DIR="./demo/dataflow-csv2bq"
    #     EOT
    #     05 = try("Open ${google_composer_environment.orch-cmp-0[0].config.0.airflow_uri} and run uploaded DAG.", "Composer not deployed")
    #     06 = <<EOT
    #            bq query --project_id=${module.dwh-conf-project.project_id} --use_legacy_sql=false 'SELECT * EXCEPT (name, surname) FROM `${module.dwh-conf-project.project_id}.${module.dwh-conf-bq-0.dataset_id}.customer_purchase` LIMIT 1000'"
    #          EOT
  }
}

output "gcs-buckets" {
  description = "GCS buckets."
  sensitive   = true
  value = {
    landing-cs-0    = module.land-sa-cs-0,
    processing-cs-0 = module.processing-cs-0,
    cur-cs-0        = module.cur-cs-0,
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
      landing    = module.land-project.number,
      common     = module.common-project.number,
      curated    = module.cur-project.number,
      processing = module.processing-project.number,
    }
    project_id = {
      landing    = module.land-project.project_id,
      common     = module.common-project.project_id,
      curated    = module.cur-project.project_id,
      processing = module.processing-project.project_id,
    }
  }
}

output "dataproc-hystory-server" {
  description = "Dataproc hystory server"
  value       = module.processing-dp-cluster.instance_names
}

output "vpc_network" {
  description = "VPC network."
  value = {
    processing_dataproc = local.processing_dp_vpc
    processing_composer = local.processing_vpc
  }
}

output "vpc_subnet" {
  description = "VPC subnetworks."
  value = {
    processing_dataproc = local.processing_dp_subnet
    processing_composer = local.processing_subnet
  }
}

output "dataproc_cluster" {
  description = "List of bucket names which have been assigned to the cluster."
  value = {
    bucket_names   = module.processing-dp-cluster.bucket_names
    http_ports     = module.processing-dp-cluster.http_ports
    instance_names = module.processing-dp-cluster.instance_names
    name           = module.processing-dp-cluster.name
  }
}
