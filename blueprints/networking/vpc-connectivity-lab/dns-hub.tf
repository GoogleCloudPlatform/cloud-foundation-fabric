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

# tfdoc:file:description DNS setup.

module "hub-dns" {
  source     = "../../../modules/dns"
  project_id = module.project.project_id
  name       = "${var.prefix}-example"
  zone_config = {
    domain = "example."
    private = {
      client_networks = [
        module.hub-vpc.self_link,
        module.ext-vpc.self_link,
        module.spoke-peering-a-vpc.self_link,
        module.spoke-peering-b-vpc.self_link,
        module.spoke-vpn-a-vpc.self_link,
        module.spoke-vpn-b-vpc.self_link,
      ]
    }
  }
  recordsets = merge({
    "A localhost" = { records = ["127.0.0.1"] }
    },
    var.test_vms
    ? { for instance, _ in local.test-vms : "A ${instance}" => { records = [module.test-vms[instance].internal_ip] } }
  : {})
}
