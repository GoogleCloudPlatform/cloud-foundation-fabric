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

# tfdoc:file:description Production spoke DNS zones and peerings setup.

# GCP-specific environment zone

module "prod-dns-private-zone" {
  source          = "../../../modules/dns"
  project_id      = module.prod-spoke-project.project_id
  type            = "private"
  name            = "prod-gcp-example-com"
  domain          = "prod.gcp.example.com."
  client_networks = [module.prod-spoke-vpc.self_link]
  recordsets = {
    "A localhost" = { records = ["127.0.0.1"] }
  }
}

moved {
  from = module.prod-onprem-example-dns-forwarding
  to   = module.prod-dns-fwd-onprem-example
}

module "prod-dns-fwd-onprem-example" {
  source          = "../../../modules/dns"
  project_id      = module.prod-spoke-project.project_id
  type            = "forwarding"
  name            = "example-com"
  domain          = "onprem.example.com."
  client_networks = [module.prod-spoke-vpc.self_link]
  forwarders      = { for ip in var.dns.prod : ip => null }
}

moved {
  from = module.prod-reverse-10-dns-forwarding
  to   = module.prod-dns-fwd-onprem-rev-10
}

module "prod-dns-fwd-onprem-rev-10" {
  source          = "../../../modules/dns"
  project_id      = module.prod-spoke-project.project_id
  type            = "forwarding"
  name            = "root-reverse-10"
  domain          = "10.in-addr.arpa."
  client_networks = [module.prod-spoke-vpc.self_link]
  forwarders      = { for ip in var.dns.prod : ip => null }
}

# Google APIs

module "prod-dns-policy-googleapis" {
  source     = "../../../modules/dns-response-policy"
  project_id = module.prod-spoke-project.project_id
  name       = "googleapis"
  networks = {
    prod = module.prod-spoke-vpc.self_link
  }
  rules = merge(
    {
      googleapis-all = {
        dns_name = "*.googleapis.com."
        local_data = { CNAME = { rrdatas = [
          "private.googleapis.com."
        ] } }
      }
      googleapis-private = {
        dns_name = "private.googleapis.com."
        local_data = { A = { rrdatas = [
          "199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"
        ] } }
      }
      googleapis-restricted = {
        dns_name = "restricted.googleapis.com."
        local_data = { A = { rrdatas = [
          "199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"
        ] } }
      }
    },
    {
      for k, v in local.googleapis_domains : k => {
        dns_name = v
        local_data = { CNAME = { rrdatas = [
          "private.googleapis.com."
        ] } }
      }
    }
  )
}
