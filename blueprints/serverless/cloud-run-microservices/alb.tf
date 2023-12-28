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

# tfdoc:file:description Internal Application Load Balancer resource.

# Internal Application Load Balancer in main (host) project
module "int-alb" {
  source     = "../../../modules/net-lb-app-int"
  count      = local.two_projects == true ? 1 : 0
  project_id = module.main-project.project_id
  name       = "int-alb-cr"
  region     = var.region
  backend_service_configs = {
    default = {
      project_id = module.service-project[0].project_id
      backends = [{
        group = "cr-neg"
      }]
      health_checks = []
    }
  }
  health_check_configs = {}
  neg_configs = {
    cr-neg = {
      project_id = module.service-project[0].project_id
      cloudrun = {
        region = var.region
        target_service = {
          name = local.svc_b_name
        }
      }
    }
  }
  vpc_config = {
    network    = module.vpc-main.self_link
    subnetwork = module.vpc-main.subnet_self_links["${var.region}/subnet-main"]
  }
}
