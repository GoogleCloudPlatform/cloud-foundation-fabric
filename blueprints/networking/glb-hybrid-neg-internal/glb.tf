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

# tfdoc:file:description External Global Load Balancer.

module "hybrid-glb" {
  source     = "../../../modules/net-lb-app-ext"
  project_id = module.project_landing.project_id
  name       = "hybrid-glb"
  backend_service_configs = {
    default = {
      backends = [
        {
          backend        = "neg-primary"
          balancing_mode = "RATE"
          max_rate       = { per_endpoint = 100 }
        },
        {
          backend        = "neg-secondary"
          balancing_mode = "RATE"
          max_rate       = { per_endpoint = 100 }
        }
      ]
    }
  }
  neg_configs = {
    neg-primary = {
      hybrid = {
        network = module.vpc_landing_untrusted.name
        zone    = local.zones["primary"]
        endpoints = {
          primary = {
            ip_address = (var.ilb_create
              ? module.test_vm_ilbs["primary"].forwarding_rule_addresses[""]
              : module.test_vms["primary"].internal_ip
            )
            port = 80
          }
        }
      }
    }
    neg-secondary = {
      hybrid = {
        network = module.vpc_landing_untrusted.name
        zone    = local.zones["secondary"]
        endpoints = {
          secondary = {
            ip_address = (var.ilb_create
              ? module.test_vm_ilbs["secondary"].forwarding_rule_addresses[""]
              : module.test_vms["secondary"].internal_ip
            )
            port = 80
          }
        }
      }
    }
  }
}
