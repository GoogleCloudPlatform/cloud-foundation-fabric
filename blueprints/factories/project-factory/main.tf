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

module "projects" {
  source              = "../../../modules/project"
  for_each            = local.projects
  billing_account     = each.value.billing_account
  name                = each.key
  parent              = try(each.value.parent, null)
  prefix              = each.value.prefix
  auto_create_network = try(each.value.auto_create_network, false)
  compute_metadata    = try(each.value.compute_metadata, {})
  # TODO: concat lists for each key
  contacts = merge(
    each.value.contacts, var.data_merges.contacts
  )
  default_service_account = try(each.value.default_service_account, "keep")
  descriptive_name        = try(each.value.descriptive_name, null)
  group_iam               = try(each.value.group_iam, {})
  iam                     = try(each.value.iam, {})
  iam_bindings            = try(each.value.iam_bindings, {})
  iam_bindings_additive   = try(each.value.iam_bindings_additive, {})
  labels = merge(
    each.value.labels, var.data_merges.labels
  )
  lien_reason         = try(each.value.lien_reason, null)
  logging_data_access = try(each.value.logging_data_access, {})
  logging_exclusions  = try(each.value.logging_exclusions, {})
  logging_sinks       = try(each.value.logging_sinks, {})
  metric_scopes = distinct(concat(
    each.value.metric_scopes, var.data_merges.metric_scopes
  ))
  service_encryption_key_ids = merge(
    each.value.service_encryption_key_ids,
    var.data_merges.service_encryption_key_ids
  )
  service_perimeter_bridges = distinct(concat(
    each.value.service_perimeter_bridges,
    var.data_merges.service_perimeter_bridges
  ))
  service_perimeter_standard = each.value.service_perimeter_standard
  services = distinct(concat(
    each.value.services,
    var.data_merges.services
  ))
  shared_vpc_service_config = each.value.shared_vpc_service_config
  tag_bindings = merge(
    each.value.tag_bindings,
    var.data_merges.tag_bindings
  )
}

module "service-accounts" {
  source = "../../../modules/iam-service-account"
  for_each = {
    for k in local.service_accounts : "${k.project}-${k.name}" => k
  }
  name       = each.value.name
  project_id = module.projects[each.value.project].project_id
  iam_project_roles = (
    try(each.value.options.default_roles, null) == null
    ? {}
    : {
      (module.projects[each.value.project].project_id) = [
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter"
      ]
    }
  )
}
