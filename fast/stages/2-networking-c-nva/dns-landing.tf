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

# tfdoc:file:description Landing DNS zones and peerings setup.

locals {
  googleapis_domains = {
    accounts           = "accounts.google.com."
    backupdr-cloud     = "backupdr.cloud.google.com."
    backupdr-cloud-all = "*.backupdr.cloud.google.com."
    backupdr-gu        = "backupdr.googleusercontent.google.com."
    backupdr-gu-all    = "*.backupdr.googleusercontent.google.com."
    cloudfunctions     = "*.cloudfunctions.net."
    cloudproxy         = "*.cloudproxy.app."
    composer-cloud-all = "*.composer.cloud.google.com."
    composer-gu-all    = "*.composer.googleusercontent.com."
    datafusion-all     = "*.datafusion.cloud.google.com."
    datafusion-gu-all  = "*.datafusion.googleusercontent.com."
    dataproc           = "dataproc.cloud.google.com."
    dataproc-all       = "*.dataproc.cloud.google.com."
    dataproc-gu        = "dataproc.googleusercontent.com."
    dataproc-gu-all    = "*.dataproc.googleusercontent.com."
    dl                 = "dl.google.com."
    gcr                = "gcr.io."
    gcr-all            = "*.gcr.io."
    gstatic-all        = "*.gstatic.com."
    notebooks-all      = "*.notebooks.cloud.google.com."
    notebooks-gu-all   = "*.notebooks.googleusercontent.com."
    packages-cloud     = "packages.cloud.google.com."
    packages-cloud-all = "*.packages.cloud.google.com."
    pkgdev             = "pkg.dev."
    pkgdev-all         = "*.pkg.dev."
    pkigoog            = "pki.goog."
    pkigoog-all        = "*.pki.goog."
    run-all            = "*.run.app."
    source             = "source.developers.google.com."
  }
}

# forwarding to on-prem DNS resolvers

moved {
  from = module.onprem-example-dns-forwarding
  to   = module.landing-dns-fwd-onprem-example
}

module "landing-dns-fwd-onprem-example" {
  source     = "../../../modules/dns"
  project_id = module.landing-project.project_id
  type       = "forwarding"
  name       = "example-com"
  domain     = "onprem.example.com."
  client_networks = [
    module.landing-untrusted-vpc.self_link,
    module.landing-trusted-vpc.self_link
  ]
  forwarders = { for ip in var.dns.onprem : ip => null }
}

moved {
  from = module.reverse-10-dns-forwarding
  to   = module.landing-dns-fwd-onprem-rev-10
}

module "landing-dns-fwd-onprem-rev-10" {
  source     = "../../../modules/dns"
  project_id = module.landing-project.project_id
  type       = "forwarding"
  name       = "root-reverse-10"
  domain     = "10.in-addr.arpa."
  client_networks = [
    module.landing-untrusted-vpc.self_link,
    module.landing-trusted-vpc.self_link
  ]
  forwarders = { for ip in var.dns.onprem : ip => null }
}

moved {
  from = module.gcp-example-dns-private-zone
  to   = module.landing-dns-priv-gcp
}

module "landing-dns-priv-gcp" {
  source     = "../../../modules/dns"
  project_id = module.landing-project.project_id
  type       = "private"
  name       = "gcp-example-com"
  domain     = "gcp.example.com."
  client_networks = [
    module.landing-untrusted-vpc.self_link,
    module.landing-trusted-vpc.self_link
  ]
  recordsets = {
    "A localhost" = { records = ["127.0.0.1"] }
  }
}

# Google APIs

module "landing-dns-policy-googleapis" {
  source     = "../../../modules/dns-response-policy"
  project_id = module.landing-project.project_id
  name       = "googleapis"
  networks = {
    landing-trusted   = module.landing-trusted-vpc.self_link
    landing-untrusted = module.landing-untrusted-vpc.self_link
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
