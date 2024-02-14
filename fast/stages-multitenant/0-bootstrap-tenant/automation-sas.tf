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

# tfdoc:file:description Tenant automation stage 2 and 3 service accounts.

locals {
  branch_sas = {
    dp-dev = {
      condition = join(" && ", [
        "resource.matchTag('${local.tag_keys.context}', 'data')",
        "resource.matchTag('${local.tag_keys.environment}', 'development')"
      ])
      description = "data platform dev"
      flag        = "data_platform"
    }
    dp-prod = {
      condition = join(" && ", [
        "resource.matchTag('${local.tag_keys.context}', 'data')",
        "resource.matchTag('${local.tag_keys.environment}', 'production')"
      ])
      description = "data platform prod"
      flag        = "data_platform"
    }
    gke-dev = {
      condition = join(" && ", [
        "resource.matchTag('${local.tag_keys.context}', 'gke')",
        "resource.matchTag('${local.tag_keys.environment}', 'development')"
      ])
      description = "GKE dev"
      flag        = "gke"
    }
    gke-prod = {
      condition = join(" && ", [
        "resource.matchTag('${local.tag_keys.context}', 'gke')",
        "resource.matchTag('${local.tag_keys.environment}', 'production')"
      ])
      description = "GKE prod"
      flag        = "gke"
    }
    networking = {
      condition   = "resource.matchTag('${local.tag_keys.context}', 'networking')"
      description = "networking"
      flag        = "-"
    }
    pf-dev = {
      condition   = "resource.matchTag('${local.tag_keys.environment}', 'development')"
      description = "project factory dev"
      flag        = "project_factory"
    }
    pf-prod = {
      condition   = "resource.matchTag('${local.tag_keys.environment}', 'production')"
      description = "project factory prod"
      flag        = "project_factory"
    }
    sandbox = {
      condition   = "resource.matchTag('${local.tag_keys.context}', 'sandbox')"
      description = "sandbox"
      flag        = "sandbox"
    }
    security = {
      condition   = "resource.matchTag('${local.tag_keys.context}', 'security')"
      description = "security"
      flag        = "-"
    }
    teams = {
      condition   = "resource.matchTag('${local.tag_keys.context}', 'teams')"
      description = "teams"
      flag        = "teams"
    }
  }
}

module "automation-tf-resman-sa-stage2-3" {
  source = "../../../modules/iam-service-account"
  for_each = {
    for k, v in local.branch_sas :
    k => v if lookup(local.fast_features, v.flag, true)
  }
  project_id   = module.automation-project.project_id
  name         = "${each.key}-0"
  display_name = "Terraform ${each.value.description} service account."
  prefix       = local.prefix
  iam_billing_roles = local.billing_mode == "resource" ? {
    (var.billing_account.id) = [
      "roles/billing.user", "roles/billing.costsManager"
    ]
  } : {}
  iam_organization_roles = local.billing_mode == "org" ? {
    (var.organization.id) = [
      "roles/billing.user", "roles/billing.costsManager"
    ]
  } : {}
}

# assign org policy admin with a tag-based condition to stage 2 and 3 SAs
# TODO: move to new iam_bindings_additive in the organization module

resource "google_organization_iam_member" "org_policy_admin_stage2_3" {
  for_each = {
    for k, v in module.automation-tf-resman-sa-stage2-3 : k => v.iam_email
  }
  org_id = var.organization.id
  role   = "roles/orgpolicy.policyAdmin"
  member = each.value
  condition {
    title = "org_policy_tag_${var.tenant_config.short_name}_${each.key}_scoped"
    description = join("", [
      "Org policy tag scoped grant for tenant ${var.tenant_config.short_name} ",
      local.branch_sas[each.key].description
    ])
    expression = join(" && ", [
      local.iam_tenant_condition, local.branch_sas[each.key].condition
    ])
  }
}

# assign custom tenant network admin role to networking SA

resource "google_organization_iam_member" "tenant_network_admin" {
  org_id = var.organization.id
  role   = var.custom_roles.tenant_network_admin
  member = module.automation-tf-resman-sa-stage2-3["networking"].iam_email
}
