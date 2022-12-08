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

module "project" {
  source = "../../../modules/project"
  billing_account = (var.project_create != null
    ? var.project_create.billing_account_id
    : null
  )
  parent = (var.project_create != null
    ? var.project_create.parent
    : null
  )
  name           = var.project_id
  project_create = var.project_create != null
  services = [
    "apigee.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "logging.googleapis.com",
    "compute.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com"
  ]
  iam = {
    "roles/bigquery.jobUser" = [
      module.function_gcs2bq.service_account_iam_email
    ]
    "roles/logging.logWriter" = [
      module.function_export.service_account_iam_email
    ]
    "roles/logging.logWriter" = [
      module.function_gcs2bq.service_account_iam_email
    ]
    "roles/apigee.admin" = [
      module.function_export.service_account_iam_email
    ]
    "roles/storage.admin" = [
      "serviceAccount:${module.project.service_accounts.robots.apigee}"
    ]
  }
}

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = var.organization.authorized_network
  vpc_create = var.vpc_create
  subnets_psc = [for k, v in var.psc_config : {
    ip_cidr_range = v
    name          = "subnet-psc-${k}"
    region        = k
  }]
  psa_config = {
    ranges = {
      for k, v in var.instances : "apigee-${k}" => v.psa_ip_cidr_range
    }
  }
}

module "apigee" {
  source       = "../../../modules/apigee"
  project_id   = module.project.project_id
  organization = var.organization
  envgroups    = var.envgroups
  environments = var.environments
  instances    = var.instances
  depends_on = [
    module.vpc
  ]
}

module "glb" {
  source              = "../../../modules/net-glb"
  name                = "glb"
  project_id          = module.project.project_id
  protocol            = "HTTPS"
  use_classic_version = false
  backend_service_configs = {
    default = {
      backends = [for k, v in var.instances : { backend = k }]
      protocol = "HTTPS"
    }
  }
  health_check_configs = {
    default = {
      https = { port_specification = "USE_SERVING_PORT" }
    }
  }
  neg_configs = {
    for k, v in var.instances : k => {
      psc = {
        region         = v.region
        target_service = module.apigee.instances[k].service_attachment
        network        = module.vpc.network.self_link
        subnetwork = (
          module.vpc.subnets_psc["${v.region}/subnet-psc-${v.region}"].self_link
        )
      }
    }
  }
  ssl_certificates = {
    managed_config = {
      for k, v in var.envgroups : k => { domains = [v] }
    }
  }
}

module "pubsub_export" {
  source     = "../../../modules/pubsub"
  project_id = module.project.project_id
  name       = "topic-export"
}

module "bucket_export" {
  source     = "../../../modules/gcs"
  project_id = module.project.project_id
  name       = "${module.project.project_id}-export"
  iam = {
    "roles/storage.objectViewer" = [
      module.function_gcs2bq.service_account_iam_email
    ]
  }
  notification_config = {
    enabled           = true
    payload_format    = "JSON_API_V1"
    sa_email          = module.project.service_accounts.robots.storage
    topic_name        = "topic-gcs2bq"
    event_types       = ["OBJECT_FINALIZE"]
    custom_attributes = {}
  }
}

module "function_export" {
  source           = "../../../modules/cloud-function"
  project_id       = module.project.project_id
  name             = "export"
  bucket_name      = "${module.project.project_id}-code-export"
  region           = var.organization.analytics_region
  ingress_settings = "ALLOW_INTERNAL_ONLY"
  bucket_config = {
    location             = null
    lifecycle_delete_age = 1
  }
  bundle_config = {
    source_dir  = "${path.module}/functions/export"
    output_path = "${path.module}/bundle-export.zip"
    excludes    = null
  }
  function_config = {
    entry_point = "export"
    instances   = null
    memory      = null
    runtime     = "nodejs16"
    timeout     = 180
  }
  environment_variables = {
    ORGANIZATION = module.apigee.org_name,
    ENVIRONMENTS = join(",", [for k, v in module.apigee.environments : k])
    DATASTORE    = var.datastore_name
  }
  trigger_config = {
    event    = "google.pubsub.topic.publish"
    resource = module.pubsub_export.id
    retry    = null
  }
  service_account_create = true
}

module "function_gcs2bq" {
  source           = "../../../modules/cloud-function"
  project_id       = module.project.project_id
  name             = "gcs2bq"
  bucket_name      = "${module.project.project_id}-code-gcs2bq"
  region           = var.organization.analytics_region
  ingress_settings = "ALLOW_INTERNAL_ONLY"
  bucket_config = {
    location             = null
    lifecycle_delete_age = 1
  }
  bundle_config = {
    source_dir  = "${path.module}/functions/gcs2bq"
    output_path = "${path.module}/bundle-gcs2bq.zip"
    excludes    = null
  }
  function_config = {
    entry_point = "gcs2bq"
    instances   = null
    memory      = null
    runtime     = "nodejs16"
    timeout     = 180
  }
  environment_variables = {
    DATASET  = module.bigquery_dataset.dataset_id
    TABLE    = module.bigquery_dataset.tables["analytics"].table_id
    LOCATION = var.organization.analytics_region
  }
  trigger_config = {
    event    = "google.pubsub.topic.publish"
    resource = module.bucket_export.topic
    retry    = null
  }
  service_account_create = true
}

module "bigquery_dataset" {
  source     = "../../../modules/bigquery-dataset"
  project_id = module.project.project_id
  id         = "apigee"
  location   = var.organization.analytics_region
  tables = {
    analytics = {
      friendly_name = "analytics"
      labels        = {}
      options       = null
      partitioning = {
        field = "client_received_end_timestamp"
        range = null
        time  = { type = "DAY", expiration_ms = null }
      }
      schema              = file("${path.module}/functions/gcs2bq/schema.json")
      deletion_protection = false
    }
  }
  iam = {
    "roles/bigquery.dataEditor" = [
      module.function_gcs2bq.service_account_iam_email
    ]
  }
}

resource "google_app_engine_application" "app" {
  project = module.project.project_id
  location_id = (
    (
      var.organization.analytics_region == "europe-west1" ||
      var.organization.analytics_region == "us-central1"
    )
    ? substr(
      var.organization.analytics_region, 0, length(var.organization.analytics_region) - 1
    )
    : var.organization.analytics_region
  )
}

resource "google_cloud_scheduler_job" "job" {
  name             = "export"
  schedule         = "0 4 * * *"
  time_zone        = "Etc/UTC"
  attempt_deadline = "320s"
  project          = module.project.project_id
  region           = var.organization.analytics_region
  pubsub_target {
    topic_name = module.pubsub_export.id
    data       = base64encode("test")
  }
}

resource "local_file" "create_datastore_file" {
  content = templatefile("${path.module}/templates/create-datastore.sh.tpl", {
    org_name       = module.apigee.org_name
    project_id     = module.project.project_id
    datastore_name = var.datastore_name
    bucket_name    = module.bucket_export.name
    path           = var.path
  })
  filename        = "${path.module}/create-datastore.sh"
  file_permission = "0777"
}

resource "local_file" "deploy_apiproxy_file" {
  content = templatefile("${path.module}/templates/deploy-apiproxy.sh.tpl", {
    org_name = module.apigee.org_name
  })
  filename        = "${path.module}/deploy-apiproxy.sh"
  file_permission = "0777"
}
