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
  organization = try(
    yamldecode(file("${local._paths.organization}/.config.yaml")), {}
  )
}

resource "terraform_data" "precondition" {
  lifecycle {
    precondition {
      condition     = try(local.ctx.organization.id, null) != null
      error_message = "No organization id available from context."
    }
  }
}

module "organization" {
  source          = "../../modules/organization"
  organization_id = "organizations/${try(local.ctx.organization.id, 000)}"
  logging_settings = (
    try(local.organization.logging.storage_location, null) == null
    ? {}
    : {
      storage_location = lookup(
        local.ctx_locations,
        local.organization.logging.storage_location,
        local.organization.logging.storage_location
      )
    }
  )
  factories_config = {
    custom_roles = "${local._paths.organization}/custom-roles"
  }
}

module "organization-iam" {
  source          = "../../modules/organization"
  organization_id = module.organization.id
  factories_config = {
    org_policies = "${local._paths.organization}/org-policies"
    tags         = "${local._paths.organization}/tags"
    context = {
      org_policies = {
        organization = local.ctx.organization
      }
    }
  }
}

# output "foo" { value = local.organization }
