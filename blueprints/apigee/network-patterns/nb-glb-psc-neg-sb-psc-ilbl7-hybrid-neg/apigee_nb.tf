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

module "glb" {
  source              = "../../../../modules/net-lb-app-ext"
  name                = "glb"
  project_id          = module.apigee_project.project_id
  protocol            = "HTTPS"
  use_classic_version = false
  backend_service_configs = {
    default = {
      backends      = [{ backend = "neg-0" }]
      protocol      = "HTTPS"
      health_checks = []
    }
  }
  neg_configs = {
    neg-0 = {
      psc = {
        region         = var.region
        target_service = module.apigee.instances[var.region].service_attachment
        network        = module.apigee_vpc.network.self_link
        subnetwork = (
          module.apigee_vpc.subnets_psc["${var.region}/subnet-psc"].self_link
        )
      }
    }
  }
  ssl_certificates = {
    managed_configs = {
      default = {
        domains = [var.hostname]
      }
    }
  }

}
