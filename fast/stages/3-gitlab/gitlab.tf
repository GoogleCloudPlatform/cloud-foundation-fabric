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

module "gitlab_instance" {
  source           = "../../../blueprints/third-party-solutions/gitlab"
  admin_principals = [
    "serviceAccount:${var.service_accounts.gitlab}"
  ]
  cloudsql_config        = var.cloudsql_config
  gcs_config             = var.gcs_config
  gitlab_config          = var.gitlab_config
  gitlab_instance_config = var.gitlab_instance_config
  network_config         = {
    host_project      = var.host_project_ids.prod-landing
    network_self_link = var.vpc_self_links.prod-landing
    subnet_self_link  = var.subnet_self_links.prod-landing["${var.regions.primary}/landing-gitlab-server-ew1"]
  }
  prefix         = var.prefix
  project_create = {
    billing_account_id = var.billing_account.id
    parent             = var.folder_ids.gitlab
  }
  project_id   = "prod-gitlab-0"
  redis_config = var.redis_config
  region       = var.regions.primary
}

data "google_dns_managed_zone" "landing_dns_priv_gcp" {
  project = var.host_project_ids.prod-landing
  name    = "gcp-example-com"
}

resource "google_dns_record_set" "gitlab_server" {
  project = var.host_project_ids.prod-landing
  name    = "gitlab.${data.google_dns_managed_zone.landing_dns_priv_gcp.dns_name}"
  type    = "A"
  ttl     = 300

  managed_zone = data.google_dns_managed_zone.landing_dns_priv_gcp.name

  rrdatas = [
    module.gitlab_instance.gitlab_ilb_ip
  ]
}
