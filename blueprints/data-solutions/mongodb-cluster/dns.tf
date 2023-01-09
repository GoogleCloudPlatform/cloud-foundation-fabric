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

# tfdoc:file:description Cloud DNS resources.

# Private DNS domain for mongodb+srv connectivity
module "private-dns" {
  source          = "../../../modules/dns"
  project_id      = module.project.project_id
  type            = "private"
  name            = format("%s-mongodb-internal", var.cluster_id)
  domain          = local.private_dns_domain
  client_networks = [module.vpc.self_link]
  recordsets = {
    "TXT ${local.private_dns_domain}"               = { ttl = 600, records = ["init"], create_only = true }
    "SRV _mongodb._tcp.${local.private_dns_domain}" = { ttl = 30, records = ["0 0 27107 localhost."], create_only = true }
  }
}
