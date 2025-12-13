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
  ctx_condition_vars = {
    custom_roles = merge(
      local.ctx.custom_roles,
      module.organization[0].custom_role_id
    )
    organization = {
      id          = local.organization_id
      customer_id = local.organization.customer_id
      domain      = local.organization.domain
    }
    tag_keys = merge(
      local.ctx.tag_keys,
      local.org_tag_keys
    )
    tag_values = merge(
      local.ctx.tag_values,
      local.org_tag_values
    )
  }
  # prepare organization data
  organization = merge(
    # initialize required attributes
    { customer_id = null, domain = null, id = null },
    # merge defaults
    lookup(local.defaults, "organization", {}),
    # merge attributes defined in yaml
    try(yamldecode(file("${local.paths.organization}/.config.yaml")), {})
  )
  # interpolate organization id if required
  organization_id = (
    local.organization.id == "$defaults:organization/id"
    ? try(local.defaults.organization.id, local.organization.id)
    : local.organization.id
  )
  # build map of predefined groups if organization domain is set
  org_iam_principals = local.organization.domain == null ? {} : {
    domain                  = "domain:${local.organization.domain}"
    gcp-billing-admins      = "group:gcp-billing-admins@${local.organization.domain}"
    gcp-devops              = "group:gcp-devops@${local.organization.domain}"
    gcp-network-admins      = "group:gcp-network-admins@${local.organization.domain}"
    gcp-organization-admins = "group:gcp-organization-admins@${local.organization.domain}"
    gcp-secops-admins       = "group:gcp-secops-admins@${local.organization.domain}"
    gcp-security-admins     = "group:gcp-security-admins@${local.organization.domain}"
    gcp-support             = "group:gcp-support@${local.organization.domain}"
  }
  org_tag_keys = {
    for k, v in module.organization[0].tag_keys : k => v.id
  }
  org_tag_values = {
    for k, v in module.organization[0].tag_values : k => v.id
  }
}

module "organization" {
  source           = "../../../modules/organization"
  count            = local.organization_id != null ? 1 : 0
  organization_id  = "organizations/${local.organization_id}"
  logging_settings = lookup(local.organization, "logging", null)
  context = {
    condition_vars = {
      organization = {
        id = local.organization_id
      }
    }
    email_addresses = local.ctx.email_addresses
    locations       = local.ctx.locations
  }
  contacts = lookup(local.organization, "contacts", {})
  factories_config = {
    org_policy_custom_constraints = "${local.paths.organization}/custom-constraints"
    custom_roles                  = "${local.paths.organization}/custom-roles"
    tags                          = "${local.paths.organization}/tags"
    scc_sha_custom_modules        = "${local.paths.organization}/scc-sha-custom-modules"
  }
  tags_config = {
    ignore_iam = true
  }
  workforce_identity_config = try(
    local.organization.workforce_identity_config, null
  )
}

module "organization-iam" {
  source          = "../../../modules/organization"
  count           = local.organization.id != null ? 1 : 0
  organization_id = module.organization[0].id
  context = merge(local.ctx, {
    condition_vars = merge(
      local.ctx_condition_vars,
      { folder_ids = module.factory.folder_ids },
      { project_ids = module.factory.project_ids }
    )
    custom_roles = merge(
      local.ctx.custom_roles,
      module.organization[0].custom_role_id
    )
    iam_principals = merge(
      local.ctx.iam_principals,
      module.factory.iam_principals
    )
    log_buckets = module.factory.log_buckets
    project_ids = merge(
      local.ctx.project_ids, module.factory.project_ids
    )
    storage_buckets = module.factory.storage_buckets
    tag_keys = merge(
      local.ctx.tag_keys,
      local.org_tag_keys
    )
    tag_values = merge(
      local.ctx.tag_values,
      local.org_tag_values
    )
  })
  factories_config = {
    org_policies = "${local.paths.organization}/org-policies"
    tags         = "${local.paths.organization}/tags"
  }
  iam = lookup(
    local.organization, "iam", {}
  )
  iam_by_principals = lookup(
    local.organization, "iam_by_principals", {}
  )
  iam_bindings = lookup(
    local.organization, "iam_bindings", {}
  )
  iam_bindings_additive = lookup(
    local.organization, "iam_bindings_additive", {}
  )
  iam_by_principals_additive = lookup(
    local.organization, "iam_by_principals_additive", {}
  )
  logging_data_access = try(local.organization.data_access_logs, {})
  logging_sinks       = try(local.organization.logging.sinks, {})
  pam_entitlements    = try(local.organization.pam_entitlements, {})
  tags_config = {
    force_context_ids = true
  }
}
