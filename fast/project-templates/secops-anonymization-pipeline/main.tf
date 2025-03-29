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
  dlp_config = var.dlp_config == null ? {
    region                 = var.regions.primary
    deidentify_template_id = google_data_loss_prevention_deidentify_template.dlp_deidentify_template.0.id
    inspect_template_id    = google_data_loss_prevention_inspect_template.dlp_inspect_template.0.id
  } : var.dlp_config
}

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  billing_account = try(var.project_create_config.billing_account, null)
  parent          = try(var.project_create_config.parent, null)
  project_reuse   = var.project_create_config != null ? null : {}
  services = concat([
    "secretmanager.googleapis.com",
    "run.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "vpcaccess.googleapis.com",
    "dlp.googleapis.com",
    "vpcaccess.googleapis.com"
  ])
  iam = {
    "roles/dlp.reader"                        = [module.function.service_account_iam_email]
    "roles/dlp.jobsEditor"                    = [module.function.service_account_iam_email]
    "roles/serviceusage.serviceUsageConsumer" = [module.function.service_account_iam_email]
    "roles/chronicle.editor"                  = [module.function.service_account_iam_email]
  }
  iam_bindings_additive = {
    function-log-writer = {
      member = module.function.service_account_iam_email
      role   = "roles/logging.logWriter"
    }
  }
}

module "export-bucket" {
  source        = "../../../modules/gcs"
  project_id    = module.project.project_id
  name          = "secops-export"
  prefix        = var.prefix
  location      = var.regions.primary
  storage_class = "REGIONAL"
  versioning    = true
  lifecycle_rules = {
    delete = {
      action = {
        type = "Delete"
      }
      condition = {
        age = 7
      }
    }
  }
  iam = {
    "roles/storage.legacyBucketReader" = [
      "user:malachite-data-export-batch@prod.google.com",
      module.function.service_account_iam_email
    ]
    "roles/storage.objectAdmin" = [
      "user:malachite-data-export-batch@prod.google.com",
      module.function.service_account_iam_email
    ]
    "roles/storage.objectViewer" = [module.function.service_account_iam_email]
  }
}

module "anonymized-bucket" {
  count         = var.skip_anonymization ? 0 : 1
  source        = "../../../modules/gcs"
  project_id    = module.project.project_id
  name          = "anonymized-data"
  prefix        = var.prefix
  location      = var.regions.primary
  storage_class = "REGIONAL"
  versioning    = true
  lifecycle_rules = {
    delete = {
      action = {
        type = "Delete"
      }
      condition = {
        age = 7
      }
    }
  }
  iam_bindings_additive = {
    storage-legacy-reader-function = {
      role   = "roles/storage.legacyBucketReader"
      member = module.function.service_account_iam_email
    }
    storage-legacy-reader-dlp = {
      role   = "roles/storage.legacyBucketReader"
      member = "serviceAccount:service-${module.project.number}@dlp-api.iam.gserviceaccount.com"
    }
    storage-object-admin-dlp = {
      role   = "roles/storage.objectAdmin"
      member = "serviceAccount:service-${module.project.number}@dlp-api.iam.gserviceaccount.com"
    }
    storage-object-admin-function = {
      role   = "roles/storage.objectAdmin"
      member = module.function.service_account_iam_email
    }
  }
}

module "function" {
  source                 = "../../../modules/cloud-function-v2"
  project_id             = module.project.project_id
  region                 = var.regions.primary
  prefix                 = var.prefix
  name                   = "secops-anonymization"
  bucket_name            = "${var.project_id}-anonymization"
  service_account_create = true
  ingress_settings       = "ALLOW_INTERNAL_AND_GCLB"
  build_worker_pool      = var.cloud_function_config.build_worker_pool_id
  build_service_account  = var.cloud_function_config.build_sa != null ? var.cloud_function_config.build_sa : module.cloudbuild-sa.0.id
  bucket_config = {
    lifecycle_delete_age_days = 1
  }
  bundle_config = {
    path = "${path.module}/source"
  }
  environment_variables = merge({
    GCP_PROJECT                = module.project.project_id
    SKIP_ANONYMIZATION         = var.skip_anonymization
    SECOPS_SOURCE_PROJECT      = var.secops_config.source_tenant.gcp_project
    SECOPS_TARGET_PROJECT      = var.secops_config.target_tenant.gcp_project
    SECOPS_SOURCE_CUSTOMER_ID  = var.secops_config.source_tenant.customer_id
    SECOPS_TARGET_CUSTOMER_ID  = var.secops_config.target_tenant.customer_id
    SECOPS_TARGET_FORWARDER_ID = var.secops_config.target_tenant.forwarder_id
    SECOPS_REGION              = var.secops_config.region
    SECOPS_EXPORT_BUCKET       = module.export-bucket.name
    LOG_EXECUTION_ID           = "true"
    }, var.skip_anonymization ? {} : {
    SECOPS_OUTPUT_BUCKET       = module.anonymized-bucket.0.name
    DLP_DEIDENTIFY_TEMPLATE_ID = local.dlp_config.deidentify_template_id
    DLP_INSPECT_TEMPLATE_ID    = local.dlp_config.inspect_template_id
    DLP_REGION                 = local.dlp_config.region
  })
  function_config = {
    cpu             = var.cloud_function_config.cpu
    memory_mb       = var.cloud_function_config.memory_mb
    timeout_seconds = var.cloud_function_config.timeout_seconds
  }
  iam = {
    "roles/run.invoker" = [
      "serviceAccount:${module.scheduler-sa.email}"
    ]
  }
  secrets = {}
  vpc_connector = (
    var.cloud_function_config.vpc_connector == null
    ? {}
    : {
      create          = false
      name            = var.cloud_function_config.vpc_connector.name
      egress_settings = var.cloud_function_config.vpc_connector.egress_settings
    }
  )
}

module "cloudbuild-sa" {
  count      = var.cloud_function_config.build_sa == null ? 1 : 0
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "cloudbuild"
  iam_project_roles = {
    (module.project.project_id) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/artifactregistry.writer",
      "roles/storage.objectAdmin"
    ]
  }
}

module "scheduler-sa" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "secops-anonymization-scheduler"
}

resource "google_cloud_scheduler_job" "anonymization_jobs" {
  for_each         = { for k, v in var.anonymization_scheduler : k => v if !(var.skip_anonymization && k == "anonymize-data") }
  project          = module.project.project_id
  name             = "secops_${each.key}"
  description      = "Trigger SecOps anonymization function."
  schedule         = each.value
  time_zone        = "Etc/UTC"
  attempt_deadline = "320s"
  region           = var.regions.secondary
  retry_config {
    retry_count = 1
  }
  http_target {
    http_method = "POST"
    uri         = module.function.uri
    body = base64encode(jsonencode({
      ACTION = upper(each.key)
    }))
    headers = { "Content-Type" : "application/json" }
    oidc_token {
      service_account_email = module.scheduler-sa.email
      audience              = module.function.uri
    }
  }
  lifecycle {
    ignore_changes = [
      http_target
    ]
  }
}
