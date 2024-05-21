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

# tfdoc:file:description Projects factory locals.

locals {
  _hierarchy_projects = (
    {
      for f in try(fileset(local._folders_path, "**/*.yaml"), []) :
      basename(trimsuffix(f, ".yaml")) => merge(
        { parent = dirname(f) },
        yamldecode(file("${local._folders_path}/${f}"))
      )
      if !endswith(f, "/_config.yaml")
    }
  )
  _project_path = try(pathexpand(var.factories_config.projects_data_path), null)
  _projects = merge(
    {
      for f in try(fileset(local._project_path, "**/*.yaml"), []) :
      trimsuffix(f, ".yaml") => yamldecode(file("${local._project_path}/${f}"))
    },
    local._hierarchy_projects
  )
  _project_budgets = flatten([
    for k, v in local._projects : [
      for b in try(v.billing_budgets, []) : {
        budget  = b
        project = k
      }
    ]
  ])
  project_budgets = {
    for v in local._project_budgets : v.budget => v.project...
  }
  projects = {
    for k, v in local._projects : k => merge(v, {
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
      services = coalesce(
        var.data_overrides.services,
        try(v.services, null),
        var.data_defaults.services
      )
      shared_vpc_service_config = (
        try(v.shared_vpc_service_config, null) != null
        ? merge(
          {
            network_users               = []
            service_identity_iam        = {}
            service_identity_subnet_iam = {}
            service_iam_grants          = []
            network_subnet_users        = {}
          },
          v.shared_vpc_service_config
        )
        : var.data_defaults.shared_vpc_service_config
      )
      tag_bindings = coalesce(
        var.data_overrides.tag_bindings,
        try(v.tag_bindings, null),
        var.data_defaults.tag_bindings
      )
      vpc_sc = (
        var.data_overrides.vpc_sc != null
        ? var.data_overrides.vpc_sc
        : try(v.vpc_sc, var.data_defaults.vpc_sc, null)
      )
      # non-project resources
      service_accounts = try(v.service_accounts, {})
    })
  }
  service_accounts = flatten([
    for k, v in local.projects : [
      for name, opts in v.service_accounts : {
        project = k
        name    = name
        display_name = coalesce(
          try(var.data_overrides.service_accounts.display_name, null),
          try(opts.display_name, null),
          try(var.data_defaults.service_accounts.display_name, null),
          "Terraform-managed."
        )
        iam_billing_roles      = try(opts.iam_billing_roles, {})
        iam_organization_roles = try(opts.iam_organization_roles, {})
        iam_sa_roles           = try(opts.iam_sa_roles, {})
        iam_project_roles      = try(opts.iam_project_roles, {})
        iam_self_roles = distinct(concat(
          try(var.data_overrides.service_accounts.iam_self_roles, []),
          try(opts.iam_self_roles, []),
          try(var.data_defaults.service_accounts.iam_self_roles, []),
        ))
        iam_storage_roles = try(opts.iam_storage_roles, {})
        opts              = opts
      }
    ]
  ])
}
