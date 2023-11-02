/**
 * Copyright 2023 Google LLC
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

# tfdoc:file:description Cloud Run services.

resource "google_cloud_run_v2_service" "svc_a" {
  project      = module.main-project.project_id
  name         = local.svc_a_name
  location     = var.region
  ingress      = "INGRESS_TRAFFIC_ALL"
  launch_stage = "BETA" # Required to use Direct VPC Egress
  template {
    containers {
      image = var.image_configs.svc_a
    }
    dynamic "vpc_access" {
      for_each = try(var.project_configs.service.project_id, null) == null ? [""] : []
      content { # Use Serverless VPC Access connector
        connector = google_vpc_access_connector.connector[0].id
      }
    }
    dynamic "vpc_access" {
      for_each = try(var.project_configs.service.project_id, null) != null ? [""] : []
      content { # Use Direct VPC Egress
        network_interfaces {
          subnetwork = module.vpc-main.subnets["${var.region}/subnet-vpc-direct"].name
        }
      }
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "svc_a_policy" {
  project     = module.main-project.project_id
  location    = var.region
  name        = google_cloud_run_v2_service.svc_a.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

module "cloud-run-svc-b" {
  source     = "../../../modules/cloud-run"
  project_id = try(module.service-project[0].project_id, module.main-project.project_id)
  name       = local.svc_b_name
  region     = var.region
  containers = {
    default = {
      image = var.image_configs.svc_b
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  ingress_settings = "internal"
}

# Serverless VPC Access connector
# The use case where both Cloud Run services are in the same project uses
# a VPC access connector to connect from service A to service B.
# The use case with Shared VPC and internal ALB uses Direct VPC Egress.
resource "google_vpc_access_connector" "connector" {
  count   = try(var.project_configs.service.project_id, null) == null ? 1 : 0
  name    = "connector"
  project = module.main-project.project_id
  region  = var.region
  subnet {
    name       = module.vpc-main.subnets["${var.region}/subnet-vpc-access"].name
    project_id = module.main-project.project_id
  }
}
