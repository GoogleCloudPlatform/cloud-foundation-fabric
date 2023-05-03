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

# tfdoc:file:description Networking folder and hierarchical policy.

locals {
  custom_roles = coalesce(var.custom_roles, {})
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
  # combine all regions from variables and subnets
  regions = distinct(concat(
    values(var.regions),
    values(module.dev-spoke-vpc.subnet_regions),
    values(module.prod-spoke-vpc.subnet_regions),
  ))
  stage3_sas_delegated_grants = [
    "roles/composer.sharedVpcAgent",
    "roles/compute.networkUser",
    "roles/container.hostServiceAgentUser",
    "roles/vpcaccess.user",
  ]
  service_accounts = {
    for k, v in coalesce(var.service_accounts, {}) : k => "serviceAccount:${v}" if v != null
  }
}

module "folder" {
  source        = "../../../modules/folder"
  parent        = "organizations/${var.organization.id}"
  name          = "Networking"
  folder_create = var.folder_ids.networking == null
  id            = var.folder_ids.networking
  firewall_policy_factory = {
    cidr_file   = "${var.factories_config.data_dir}/cidrs.yaml"
    policy_name = var.factories_config.firewall_policy_name
    rules_file  = "${var.factories_config.data_dir}/hierarchical-policy-rules.yaml"
  }
  firewall_policy_association = {
    factory-policy = var.factories_config.firewall_policy_name
  }
}

