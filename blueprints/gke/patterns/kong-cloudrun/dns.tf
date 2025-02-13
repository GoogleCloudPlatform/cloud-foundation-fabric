/**
 * Copyright 2024 Google LLC
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

module "private_dns_ilb" {
  source     = "../../../../modules/dns"
  project_id = var.project_id
  name       = "dns-ilb"
  zone_config = {
    domain = format("%s.", var.custom_domain)
    private = {
      client_networks = [var.created_resources.vpc_id]
    }
  }
  recordsets = {
    "A " = { records = [module.ilb-l7.address] }
  }
}