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

# tfdoc:file:description DNS resources.

# DNS configuration for the PSC for Google APIs endpoint
module "private-dns-main" {
  source     = "../../../modules/dns"
  project_id = module.main-project.project_id
  name       = "cloud-run"
  zone_config = {
    domain = local.cloud_run_domain
    private = {
      client_networks = [module.vpc-main.self_link]
    }
  }
  recordsets = {
    "A *" = { records = [module.psc-addr-main.psc_addresses["psc-addr"].address] }
  }
}

# DNS configuration for the Cloud Run custom domain (when using internal ALB)
module "private-dns-main-custom" {
  source     = "../../../modules/dns"
  count      = local.two_projects == true ? 1 : 0
  project_id = module.main-project.project_id
  name       = "cloud-run-custom"
  zone_config = {
    domain = format("%s.", var.custom_domain)
    private = {
      client_networks = [module.vpc-main.self_link]
    }
  }
  recordsets = {
    "A " = { records = [module.int-alb[0].address] }
  }
}
