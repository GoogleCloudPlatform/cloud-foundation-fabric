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

# inputs
# local._projects_input - parsed data from yaml as map
# local._projects_config = object({
#   data_overrides = ...
#   data_defaults = ...
# })
# outputs:
# local._projects_output - map
locals {
  __projects_config = {
    data_defaults = merge({
      billing_account = null
      contacts        = {}
      deletion_policy = null
      factories_config = merge({
        custom_roles  = null
        observability = null
        org_policies  = null
        quotas        = null
        }, try(local._projects_config.data_defaults.factories_config, {
          custom_roles  = null
          observability = null
          org_policies  = null
          quotas        = null
        })
      )
      labels        = {}
      metric_scopes = []
      parent        = null
      prefix        = null
      project_reuse = merge({
        use_data_source = true
        attributes      = null
        }, try(local._projects_config.data_defaults.project_reuse, {
          use_data_source = true
          attributes      = null
        })
      )
      service_encryption_key_ids = {}
      services                   = []
      shared_vpc_service_config = merge(
        {
          host_project             = null
          iam_bindings_additive    = {}
          network_users            = []
          service_agent_iam        = {}
          service_agent_subnet_iam = {}
          service_iam_grants       = []
          network_subnet_users     = {}
        },
        try(local._projects_config.data_defaults.shared_vpc_service_config, {
          host_project             = null
          iam_bindings_additive    = {}
          network_users            = []
          service_agent_iam        = {}
          service_agent_subnet_iam = {}
          service_iam_grants       = []
          network_subnet_users     = {}
          }
        )
      )
      storage_location = null
      tag_bindings     = {}
      service_accounts = {}
      vpc_sc = merge({
        perimeter_name = null
        is_dry_run     = false
        }, try(local._projects_config.data_defaults.vpc_sc, {
          perimeter_name = null
          is_dry_run     = false
        })
      )
      logging_data_access = {}
      },
      try(local._projects_config.data_defaults, {})
    )
    # data_overrides default to null's, to mark that they should not override
    data_overrides = merge({
      billing_account = null
      contacts        = null
      deletion_policy = null
      factories_config = merge({
        custom_roles  = null
        observability = null
        org_policies  = null
        quotas        = null
        }, try(local._projects_config.data_overrides.factories_config, {
          custom_roles  = null
          observability = null
          org_policies  = null
          quotas        = null
        })
      )
      parent                     = null
      prefix                     = null
      service_encryption_key_ids = null
      storage_location           = null
      tag_bindings               = null
      services                   = null
      service_accounts           = null
      vpc_sc = try(
        merge(
          {
            perimeter_name = null
            is_dry_run     = false
          },
          local._projects_config.data_overrides.vpc_sc
        ),
        null
      )
      logging_data_access = null
      },
      try(local._projects_config.data_overrides, {})
    )
  }
  _projects_output = {
    # Semantics of the merges are:
    # * if data_overrides.<field> is not null, use this value
    # * if  _projects_inputs.<field> is not null, use this value
    # * use data_default value, which if not set, will provide "empty" type
    # This logic is easily implemented using coalesce, even on maps and list and allows to
    # set data_overrides.<field> to "", [] or {} to ensure, that empty value is always passed, or do
    # the same in _projects_input to prevent falling back to default value
    for k, v in local._projects_input : k => merge(v, {
      billing_account = try(coalesce( # type: string
        local.__projects_config.data_overrides.billing_account,
        try(v.billing_account, null),
        local.__projects_config.data_defaults.billing_account
      ), null)
      deletion_policy = try(coalesce( # type: string
        local.__projects_config.data_overrides.deletion_policy,
        try(v.deletion_policy, null),
        local.__projects_config.data_defaults.deletion_policy
      ), null)
      contacts = coalesce( # type: map
        local.__projects_config.data_overrides.contacts,
        try(v.contacts, null),
        local.__projects_config.data_defaults.contacts
      )
      factories_config = {  # type: object
        custom_roles = try( # type: string
          coalesce(
            local.__projects_config.data_overrides.factories_config.custom_roles,
            try(v.factories_config.custom_roles, null),
            local.__projects_config.data_defaults.factories_config.custom_roles
          ),
          null
        )
        observability = try( # type: string
          coalesce(
            local.__projects_config.data_overrides.factories_config.observability,
            try(v.factories_config.observability, null),
            local.__projects_config.data_defaults.factories_config.observability
          ),
        null)
        org_policies = try( # type: string
          coalesce(
            local.__projects_config.data_overrides.factories_config.org_policies,
            try(v.factories_config.org_policies, null),
            local.__projects_config.data_defaults.factories_config.org_policies
          ),
        null)
        quotas = try( # type: string
          coalesce(
            local.__projects_config.data_overrides.factories_config.quotas,
            try(v.factories_config.quotas, null),
            local.__projects_config.data_defaults.factories_config.quotas
          ),
        null)
      }
      iam                        = try(v.iam, {})                        # type: map(list(string))
      iam_bindings               = try(v.iam_bindings, {})               # type: map(object({...}))
      iam_bindings_additive      = try(v.iam_bindings_additive, {})      # type: map(object({...}))
      iam_by_principals_additive = try(v.iam_by_principals_additive, {}) # type: map(list(string))
      iam_by_principals          = try(v.iam_by_principals, {})          # map(list(string))
      labels = coalesce(                                                 # type: map(string)
        try(v.labels, null),
        local.__projects_config.data_defaults.labels
      )
      metric_scopes = coalesce( # type: list(string)
        try(v.metric_scopes, null),
        local.__projects_config.data_defaults.metric_scopes
      )
      name         = lookup(v, "name", basename(k)) # type: string
      org_policies = try(v.org_policies, {})        # type: map(object({...}))
      parent = try(                                 # type: string, nullable
        coalesce(
          local.__projects_config.data_overrides.parent,
          try(v.parent, null),
          local.__projects_config.data_defaults.parent
        ), null
      )
      prefix = try( # type: string, nullable
        coalesce(
          local.__projects_config.data_overrides.prefix,
          try(v.prefix, null),
          local.__projects_config.data_defaults.prefix
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
        : local.__projects_config.data_defaults.project_reuse
      )
      service_encryption_key_ids = coalesce( # type: map(list(string))
        local.__projects_config.data_overrides.service_encryption_key_ids,
        try(v.service_encryption_key_ids, null),
        local.__projects_config.data_defaults.service_encryption_key_ids
      )
      services = coalesce( # type: list(string)
        local.__projects_config.data_overrides.services,
        try(v.services, null),
        local.__projects_config.data_defaults.services
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
        ? merge(
          {
            host_project             = null
            iam_bindings_additive    = {}
            network_users            = []
            service_agent_iam        = {}
            service_agent_subnet_iam = {}
            service_iam_grants       = []
            network_subnet_users     = {}
          },
          v.shared_vpc_service_config
        )
        : local.__projects_config.data_defaults.shared_vpc_service_config
      )
      tag_bindings = coalesce( # type: map(string)
        local.__projects_config.data_overrides.tag_bindings,
        try(v.tag_bindings, null),
        local.__projects_config.data_defaults.tag_bindings
      )
      tags = {
        for tag_name, tag_data in try(v.tags, {}) : tag_name => {
          description           = try(tag_data.description, "Managed by the Terraform project-factory module.")
          id                    = try(tag_data.id, null)
          iam                   = try(tag_data.iam, {})
          iam_bindings          = try(tag_data.iam_bindings, {})
          iam_bindings_additive = try(tag_data.iam_bindings_additive, {})
          values = {
            for value_name, value_data in try(tag_data.values, {}) : value_name => {
              description           = try(value_data.description, "Managed by the Terraform project-factory module.")
              id                    = try(value_data.id, null)
              iam                   = try(value_data.iam, {})
              iam_bindings          = try(value_data.iam_bindings, {})
              iam_bindings_additive = try(value_data.iam_bindings_additive, {})
            }
          }
        }
      }
      vpc_sc = (
        local.__projects_config.data_overrides.vpc_sc != null
        ? local.__projects_config.data_overrides.vpc_sc
        : (
          try(v.vpc_sc, null) != null
          ? merge({
            perimeter_name = null
            is_dry_run     = false
          }, v.vpc_sc)
          : local.__projects_config.data_defaults.vpc_sc
        )
      )
      logging_data_access = coalesce( # type: map(object({...}))
        local.__projects_config.data_overrides.logging_data_access,
        try(v.logging_data_access, null),
        local.__projects_config.data_defaults.logging_data_access
      )
      quotas = try(v.quotas, {})
    })
  }
  # tflint-ignore: terraform_unused_declarations
  _projects_uniqueness_validation = {
    # will raise error, if the same project (derived from file name, or provided in the YAML file)
    # is used more than once
    for k, v in local._projects_output :
    "${v.prefix != null ? v.prefix : ""}-${v.name}" => k
  }
}
