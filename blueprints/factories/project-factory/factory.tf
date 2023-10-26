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

locals {
  _data = (
    var.factory_data.data != null
    ? var.factory_data.data
    : {
      for f in fileset("${local._data_path}", "**/*.yaml") :
      trimsuffix(f, ".yaml") => yamldecode(file("${local._data_path}/${f}"))
    }
  )
  _data_path = var.factory_data.data_path == null ? null : pathexpand(
    var.factory_data.data_path
  )
  projects = {
    for k, v in local._data : k => merge(v, {
      billing_account = try(coalesce(
        var.data_overrides.billing_account,
        try(v.billing_account, null),
        var.data_defaults.billing_account
      ), null)
      contacts = coalesce(
        var.data_overrides.contacts,
        try(v.contacts, null),
        var.data_defaults.contacts
      )
      labels = coalesce(
        try(v.labels, null),
        var.data_defaults.labels
      )
      metric_scopes = coalesce(
        try(v.metric_scopes, null),
        var.data_defaults.metric_scopes
      )
      org_policies = try(v.org_policies, {})
      parent = coalesce(
        var.data_overrides.parent,
        try(v.parent, null),
        var.data_defaults.parent
      )
      prefix = coalesce(
        var.data_overrides.prefix,
        try(v.prefix, null),
        var.data_defaults.prefix
      )
      service_encryption_key_ids = coalesce(
        var.data_overrides.service_encryption_key_ids,
        try(v.service_encryption_key_ids, null),
        var.data_defaults.service_encryption_key_ids
      )
      service_perimeter_bridges = coalesce(
        var.data_overrides.service_perimeter_bridges,
        try(v.service_perimeter_bridges, null),
        var.data_defaults.service_perimeter_bridges
      )
      service_perimeter_standard = try(coalesce(
        var.data_overrides.service_perimeter_standard,
        try(v.service_perimeter_standard, null),
        var.data_defaults.service_perimeter_standard
      ), null)
      services = coalesce(
        var.data_overrides.services,
        try(v.services, null),
        var.data_defaults.services
      )
      shared_vpc_service_config = (
        try(v.shared_vpc_service_config, null) != null
        ? merge(
          { service_identity_iam = {}, service_iam_grants = [] },
          v.shared_vpc_service_config
        )
        : var.data_defaults.shared_vpc_service_config
      )
      tag_bindings = coalesce(
        var.data_overrides.tag_bindings,
        try(v.tag_bindings, null),
        var.data_defaults.tag_bindings
      )
      # non-project resources
      service_accounts = coalesce(
        var.data_overrides.service_accounts,
        try(v.service_accounts, null),
        var.data_defaults.service_accounts
      )
    })
  }
  service_accounts = flatten([
    for k, v in local.projects : [
      for name, opts in v.service_accounts : {
        project           = k
        name              = name
        display_name      = try(opts.display_name, "Terraform-managed.")
        iam_project_roles = try(opts.iam_project_roles, null)
      }
    ]
  ])
}
