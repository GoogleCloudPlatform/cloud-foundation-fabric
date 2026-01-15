/**
 * Copyright 2026 Google LLC
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

# inputs:
#   local._projects_input: raw projects data
# outputs:
#   local.data_defaults: normalized defaults/overrides
#   local._projects_output: normalized project data

locals {
  _data_defaults = {
    defaults  = try(var.data_defaults, {})
    overrides = try(var.data_overrides, {})
  }
  _projects_output = {
    # Semantics of the merges are:
    #   - if data_overrides.<field> is not null, use this value
    #   - if  _projects_inputs.<field> is not null, use this value
    #   - use data_default value, which if not set, will provide "empty" type
    # This logic is easily implemented using coalesce, even on maps and list and allows to
    # set data_overrides.<field> to "", [] or {} to ensure, that empty value is always passed, or do
    # the same in _projects_input to prevent falling back to default value
    for k, v in local._projects_input : k => merge(v, {
      billing_account = try(coalesce( # type: string
        local.data_defaults.overrides.billing_account,
        try(v.billing_account, null),
        local.data_defaults.defaults.billing_account
      ), null)
      deletion_policy = try(coalesce( # type: string
        local.data_defaults.overrides.deletion_policy,
        try(v.deletion_policy, null),
        local.data_defaults.defaults.deletion_policy
      ), null)
      contacts = coalesce( # type: map
        local.data_defaults.overrides.contacts,
        try(v.contacts, null),
        local.data_defaults.defaults.contacts
      )
      factories_config              = try(v.factories_config, {})
      iam                           = try(v.iam, {})                           # type: map(list(string))
      iam_bindings                  = try(v.iam_bindings, {})                  # type: map(object({...}))
      iam_bindings_additive         = try(v.iam_bindings_additive, {})         # type: map(object({...}))
      iam_by_principals_additive    = try(v.iam_by_principals_additive, {})    # type: map(list(string))
      iam_by_principals             = try(v.iam_by_principals, {})             # map(list(string))
      iam_by_principals_conditional = try(v.iam_by_principals_conditional, {}) # map(object({...}))
      kms = {
        autokeys = try(v.kms.autokeys, {})
        keyrings = try(v.kms.keyrings, {})
      }
      labels = coalesce( # type: map(string)
        try(v.labels, null),
        local.data_defaults.defaults.labels
      )
      logging_data_access = try(v.data_access_logs, {})
      metric_scopes = coalesce( # type: list(string)
        try(v.metric_scopes, null),
        local.data_defaults.defaults.metric_scopes
      )
      descriptive_name = lookup(v, "descriptive_name", null)
      name             = lookup(v, "name", basename(k)) # type: string
      org_policies     = try(v.org_policies, {})        # type: map(object({...}))
      parent = try(                                     # type: string, nullable
        coalesce(
          local.data_defaults.overrides.parent,
          try(v.parent, null),
          local.data_defaults.defaults.parent
        ), null
      )
      prefix = try( # type: string, nullable
        coalesce(
          local.data_defaults.overrides.prefix,
          try(v.prefix, null),
          local.data_defaults.defaults.prefix
        ), null
      )
      project_reuse = ( # type: object({...})
        try(v.project_reuse, null) != null
        ? merge(
          {
            use_data_source = true
            attributes      = null
          },
          v.project_reuse
        )
        : local.data_defaults.defaults.project_reuse
      )
      quotas = try(v.quotas, {})
      service_encryption_key_ids = coalesce( # type: map(list(string))
        local.data_defaults.overrides.service_encryption_key_ids,
        try(v.service_encryption_key_ids, null),
        local.data_defaults.defaults.service_encryption_key_ids
      )
      services = coalesce( # type: list(string)
        local.data_defaults.overrides.services,
        try(v.services, null),
        local.data_defaults.defaults.services
      )
      shared_vpc_host_config = ( # type: object({...})
        try(v.shared_vpc_host_config, null) != null
        ? merge(
          { service_projects = [] },
          v.shared_vpc_host_config
        )
        : null
      )
      shared_vpc_service_config = ( # type: object({...})
        try(v.shared_vpc_service_config, null) != null
        ? {
          host_project             = try(v.shared_vpc_service_config.host_project, null)
          iam_bindings_additive    = try(v.shared_vpc_service_config.iam_bindings_additive, {})
          network_users            = try(v.shared_vpc_service_config.network_users, [])
          service_agent_iam        = try(v.shared_vpc_service_config.service_agent_iam, {})
          service_agent_subnet_iam = try(v.shared_vpc_service_config.service_agent_subnet_iam, {})
          service_iam_grants       = try(v.shared_vpc_service_config.service_iam_grants, [])
          network_subnet_users     = try(v.shared_vpc_service_config.network_subnet_users, {})
        }
        : local.data_defaults.defaults.shared_vpc_service_config
      )
      tag_bindings = coalesce( # type: map(string)
        local.data_defaults.overrides.tag_bindings,
        try(v.tag_bindings, null),
        local.data_defaults.defaults.tag_bindings
      )
      tags = {
        for tag_name, tag_data in try(v.tags, {}) : tag_name => {
          description = try(
            tag_data.description,
            "Managed by the Terraform project-factory module."
          )
          id                    = try(tag_data.id, null)
          iam                   = try(tag_data.iam, {})
          iam_bindings          = try(tag_data.iam_bindings, {})
          iam_bindings_additive = try(tag_data.iam_bindings_additive, {})
          values = {
            for value_name, value_data in try(tag_data.values, {}) :
            value_name => {
              description = try(
                value_data.description,
                "Managed by the Terraform project-factory module."
              )
              id                    = try(value_data.id, null)
              iam                   = try(value_data.iam, {})
              iam_bindings          = try(value_data.iam_bindings, {})
              iam_bindings_additive = try(value_data.iam_bindings_additive, {})
            }
          }
        }
      }
      universe = (
        local.data_defaults.overrides.universe != null
        ? local.data_defaults.overrides.universe
        : (
          try(v.universe, null) != null
          ? v.universe
          : local.data_defaults.defaults.universe
        )
      )
      vpc_sc = (
        local.data_defaults.overrides.vpc_sc != null
        ? local.data_defaults.overrides.vpc_sc
        : (
          try(v.vpc_sc, null) != null
          ? merge(
            {
              perimeter_name = null
              is_dry_run     = false
            },
            v.vpc_sc
          )
          : local.data_defaults.defaults.vpc_sc
        )
      )
      workload_identity_pools = {
        for wk, wv in try(v.workload_identity_pools, {}) : wk => {
          display_name = lookup(wv, "display_name", null)
          description  = lookup(wv, "description", null)
          disabled     = lookup(wv, "disabled", null)
          providers = {
            for pk, pv in try(wv.providers, {}) : pk => {
              display_name        = lookup(pv, "display_name", null)
              description         = lookup(pv, "description", null)
              disabled            = lookup(pv, "disabled", null)
              attribute_condition = lookup(pv, "attribute_condition", null)
              attribute_mapping   = lookup(pv, "attribute_mapping", {})
              identity_provider   = lookup(pv, "identity_provider", {})
            }
          }
        }
      }
    })
  }
  # tflint-ignore: terraform_unused_declarations
  _projects_uniqueness_validation = {
    # will raise error, if the same project (derived from file name, or provided in the YAML file)
    # is used more than once
    for k, v in local._projects_output :
    "${v.prefix != null ? v.prefix : ""}-${v.name}" => k
  }
  data_defaults = {
    defaults = merge(
      {
        billing_account = null
        contacts        = {}
        deletion_policy = null
        labels          = {}
        locations = {
          bigquery = try(local._data_defaults.defaults.locations.bigquery, null)
          logging  = try(local._data_defaults.defaults.locations.logging, null)
          storage  = try(local._data_defaults.defaults.locations.storage, null)
        }
        metric_scopes = []
        parent        = null
        prefix        = null
        project_reuse = merge(
          {
            use_data_source = true
            attributes      = null
          },
          try(local._data_defaults.defaults.project_reuse, {
            use_data_source = true
            attributes      = null
            }
          )
        )
        service_encryption_key_ids = {}
        services                   = []
        shared_vpc_service_config = {
          host_project             = try(local._data_defaults.defaults.shared_vpc_service_config.host_project, null)
          iam_bindings_additive    = try(local._data_defaults.defaults.shared_vpc_service_config.iam_bindings_additive, {})
          network_users            = try(local._data_defaults.defaults.shared_vpc_service_config.network_users, [])
          service_agent_iam        = try(local._data_defaults.defaults.shared_vpc_service_config.service_agent_iam, {})
          service_agent_subnet_iam = try(local._data_defaults.defaults.shared_vpc_service_config.service_agent_subnet_iam, {})
          service_iam_grants       = try(local._data_defaults.defaults.shared_vpc_service_config.service_iam_grants, [])
          network_subnet_users     = try(local._data_defaults.defaults.shared_vpc_service_config.network_subnet_users, {})
        }
        tag_bindings     = {}
        service_accounts = {}
        universe         = null
        vpc_sc = merge(
          {
            perimeter_name = null
            is_dry_run     = false
          },
          try(local._data_defaults.defaults.vpc_sc, {
            perimeter_name = null
            is_dry_run     = false
            }
          )
        )
      },
      try(
        local._data_defaults.defaults, {}
      )
    )
    # data_overrides default to null's, to mark that they should not override
    overrides = merge({
      billing_account = null
      contacts        = null
      deletion_policy = null
      locations = {
        bigquery = try(local._data_defaults.overrides.locations.bigquery, null)
        logging  = try(local._data_defaults.overrides.locations.logging, null)
        storage  = try(local._data_defaults.overrides.locations.storage, null)
      }
      parent                     = null
      prefix                     = null
      service_encryption_key_ids = null
      tag_bindings               = null
      services                   = null
      service_accounts           = null
      universe                   = null
      vpc_sc = try(
        merge(
          {
            perimeter_name = null
            is_dry_run     = false
          },
          local._data_defaults.overrides.vpc_sc
        ),
        null
      )
      },
      try(
        local._data_defaults.overrides, {}
      )
    )
  }
}
