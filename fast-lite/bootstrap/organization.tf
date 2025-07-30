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
  # prepare organization data
  organization = merge(
    # initialize required attributes
    { domain = null, id = null },
    # merge defaults
    lookup(local.defaults, "organization", {}),
    # merge attributes defined in yaml
    try(yamldecode(file("${local._paths.organization}/.config.yaml")), {})
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
  org_tag_values = {
    for k, v in module.organization[0].tag_values : k => v.id
  }
}

module "organization" {
  source           = "../../modules/organization"
  count            = local.organization_id != null ? 1 : 0
  organization_id  = "organizations/${local.organization_id}"
  logging_settings = lookup(local.organization, "logging", null)
  context = {
    locations = {
      default = local.defaults.locations.logging
    }
  }
  factories_config = {
    custom_roles = "${local._paths.organization}/custom-roles"
    tags         = "${local._paths.organization}/tags"
  }
}

module "organization-iam" {
  source          = "../../modules/organization"
  count           = local.organization.id != null ? 1 : 0
  organization_id = module.organization[0].id
  context = merge(local.ctx, {
    custom_roles = merge(
      local.ctx.custom_roles, module.organization[0].custom_role_id
    )
    iam_principals = merge(
      local.ctx.iam_principals,
      module.factory.iam_principals
    )
    org_policies = {
      organization = local.defaults.organization
    }
    tag_values = merge(
      local.ctx.tag_values,
      local.org_tag_values
    )
  })
  factories_config = {
    org_policies = "${local._paths.organization}/org-policies"
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
}
