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

# The use case where both Cloud Run services are in the same project uses
# a VPC access connector to connect from service A to service B.
# The use case with Shared VPC and internal ALB uses Direct VPC Egress.
module "cloud-run-svc-a" {
  source     = "../../../modules/cloud-run-v2"
  project_id = module.main-project.project_id
  name       = local.svc_a_name
  region     = var.region
  ingress    = "INGRESS_TRAFFIC_ALL"
  # Direct VPC Egress is currently in Beta. Checking its use to avoid permadiff,
  # when in GA it will need to be removed to avoid permadiff again.
  launch_stage = local.two_projects == true ? "BETA" : "GA"
  containers = {
    tester = {
      image = var.image_configs.svc_a
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  revision = {
    vpc_access = {
      egress = "ALL_TRAFFIC"
      subnet = ( # Direct VPC Egress
        local.two_projects == false
        ? null
        : module.vpc-main.subnet_ids["${var.region}/subnet-vpc-direct"]
      )
    }
  }
  vpc_connector_create = (
    local.two_projects == false
    ? {
      subnet = {
        name = module.vpc-main.subnets["${var.region}/subnet-vpc-access"].name
      }
    }
    : null
  )
}

module "cloud-run-svc-b" {
  source     = "../../../modules/cloud-run-v2"
  project_id = try(module.service-project[0].project_id, module.main-project.project_id)
  name       = local.svc_b_name
  region     = var.region
  ingress    = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  containers = {
    default = {
      image = var.image_configs.svc_b
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
}
