/**
 * Copyright 2022 Google LLC
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
      condition   = <<END
      resource.matchTag('${local.tag_keys.context}', 'data')
      &&
      resource.matchTag('${local.tag_keys.environment}', 'development')
      END
      description = "data platform dev"
      flag        = "data_platform"
    }
    dp-prod = {
      condition   = <<END
      resource.matchTag('${local.tag_keys.context}', 'data')
      &&
      resource.matchTag('${local.tag_keys.environment}', 'production')
      END
      description = "data platform prod"
      flag        = "data_platform"
    }
    gke-dev = {
      condition   = <<END
      resource.matchTag('${local.tag_keys.context}', 'gke')
      &&
      resource.matchTag('${local.tag_keys.environment}', 'development')
      END
      description = "GKE dev"
      flag        = "gke"
    }
    gke-prod = {
      condition   = <<END
      resource.matchTag('${local.tag_keys.context}', 'gke')
      &&
      resource.matchTag('${local.tag_keys.environment}', 'production')
      END
      description = "GKE prod"
      flag        = "gke"
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
    pf-prod = {
      condition   = "resource.matchTag('${local.tag_keys.context}', 'teams')"
      description = "teams"
      flag        = "teams"
    }
  }
}

module "automation-tf-resman-sa-stage2-3" {
  source = "../../../modules/iam-service-account"
  for_each = {
    for k, v in local.branch_sas : k => v if var.fast_features[v.flag]
  }
  project_id   = module.automation-project.project_id
  name         = "${each.key}-0"
  display_name = "Terraform ${each.value.description} service account."
  prefix       = local.prefix
  iam_billing_roles = !var.billing_account.is_org_level ? {
    (var.billing_account.id) = [
      "roles/billing.user", "roles/billing.costsManager"
    ]
  } : {}
  iam_organization_roles = var.billing_account.is_org_level ? {
    (var.organization.id) = [
      "roles/billing.user", "roles/billing.costsManager"
    ]
  } : {}
}

