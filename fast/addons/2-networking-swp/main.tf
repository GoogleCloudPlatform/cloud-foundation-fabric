/**
 * Copyright 2025 Google LLC
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

locals {
  ca_projects = toset([
    for k, v in var.certificate_authorities : v.project_id
  ])
  swp_projects = toset([
    for k, v in var.swp_configs : v.project_id
  ])
}

module "projects-cas" {
  source         = "../../../modules/project"
  for_each       = local.ca_projects
  name           = each.key
  project_create = false
  services = [
    "privateca.googleapis.com"
  ]
}

module "projects-swp" {
  source         = "../../../modules/project"
  for_each       = local.swp_projects
  name           = each.key
  project_create = false
  services = [
    "certificatemanager.googleapis.com",
    "networkmanagement.googleapis.com",
    "networksecurity.googleapis.com",
  ]
}

module "swp" {
  source       = "../../../modules/net-swp"
  for_each     = var.swp_configs
  project_id   = module.projects-swp[each.value.project_id].project_id
  region       = each.value.region
  name         = "${each.key}-${var.base_name}"
  network      = each.value.network_id
  subnetwork   = each.value.subnetwork_id
  certificates = each.value.certificates
  factories_config = {
    policy_rules = "${var.factories_config.policy_rules_base}/${each.key}"
    url_lists    = "${var.factories_config.url_lists_base}/${each.key}"
  }
  gateway_config        = each.value.gateway_config
  policy_rules_contexts = var.policy_rules_contexts
  service_attachment    = each.value.service_attachment
  tls_inspection_config = (
    each.value.tls_inspection_config == null
    ? null
    : (
      each.value.tls_inspection_config.id != null
      # TODO: interpolate from FAST variables
      ? each.value.tls_inspection_config.id
      : try(
        google_network_security_tls_inspection_policy.default[each.key].id,
        null
      )
    )
  )
}
