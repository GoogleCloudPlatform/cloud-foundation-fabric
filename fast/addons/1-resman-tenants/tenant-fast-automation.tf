/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description Per-tenant FAST bootstrap emulation (automation).

locals {
  _fast_tenants = {
    for k, v in local.tenants : k => merge(v, {
      groups       = coalesce(v.fast_config.groups, var.groups)
      prefix       = coalesce(v.fast_config.prefix, "${var.prefix}-${k}")
      wif_provider = try(v.fast_config.cicd_config.identity_provider, "-")
    }) if v.fast_config != null
  }
  fast_tenants = {
    for k, v in local._fast_tenants : k => merge(v, {
      stage_0_prefix = "${v.prefix}-prod"
      principals = {
        for gk, gv in v.groups : gk => (
          can(regex("^[a-zA-Z]+:", gv))
          ? gv
          : "group:${gv}@${v.organization.domain}"
        )
      }
    })
  }
}

module "tenant-automation-project" {
  source          = "../../../modules/project"
  for_each        = local.fast_tenants
  billing_account = each.value.billing_account.id
  name            = "iac-core-0"
  parent          = module.tenant-folder[each.key].id
  prefix          = each.value.stage_0_prefix
  # this is needed when destroying, resources cannot depend on the
  # project-iam module to avoid circular dependencies
  iam_bindings_additive = {
    owner_org_resman = {
      role   = "roles/owner"
      member = "serviceAccount:${var.automation.service_accounts.resman}"
    }
  }
  services = [
    "accesscontextmanager.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudquotas.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "essentialcontacts.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "orgpolicy.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
  ]
  logging_data_access = {
    "iam.googleapis.com" = {
      ADMIN_READ = []
    }
  }
}


module "tenant-automation-project-iam" {
  source         = "../../../modules/project"
  for_each       = local.fast_tenants
  name           = module.tenant-automation-project[each.key].project_id
  project_create = false
  # human (groups) IAM bindings
  iam_by_principals = {
    (each.value.principals.gcp-devops) = [
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountTokenCreator",
    ]
    (each.value.principals.gcp-organization-admins) = [
      "roles/iam.serviceAccountTokenCreator",
      "roles/iam.workloadIdentityPoolAdmin"
    ]
  }
  # machine (service accounts) IAM bindings
  iam = {
    "roles/browser" = [
      module.tenant-automation-tf-resman-r-sa[each.key].iam_email
    ]
    "roles/cloudbuild.builds.editor" = [
      module.tenant-automation-tf-resman-sa[each.key].iam_email
    ]
    "roles/cloudbuild.builds.viewer" = [
      module.tenant-automation-tf-resman-r-sa[each.key].iam_email
    ]
    "roles/iam.serviceAccountAdmin" = [
      module.tenant-automation-tf-resman-sa[each.key].iam_email
    ]
    "roles/iam.serviceAccountViewer" = [
      module.tenant-automation-tf-resman-r-sa[each.key].iam_email
    ]
    "roles/iam.workloadIdentityPoolAdmin" = [
      module.tenant-automation-tf-resman-sa[each.key].iam_email
    ]
    "roles/iam.workloadIdentityPoolViewer" = [
      module.tenant-automation-tf-resman-r-sa[each.key].iam_email
    ]
    "roles/source.admin" = [
      module.tenant-automation-tf-resman-sa[each.key].iam_email
    ]
    "roles/source.reader" = [
      module.tenant-automation-tf-resman-r-sa[each.key].iam_email
    ]
    "roles/storage.admin" = [
      module.tenant-automation-tf-resman-sa[each.key].iam_email
    ]
    (var.custom_roles["storage_viewer"]) = [
      module.tenant-automation-tf-resman-r-sa[each.key].iam_email
    ]
    "roles/viewer" = [
      "serviceAccount:${var.automation.service_accounts.resman-r}",
      module.tenant-automation-tf-resman-r-sa[each.key].iam_email
    ]
  }
  iam_bindings = {
    delegated_grants_resman = {
      members = [module.tenant-automation-tf-resman-sa[each.key].iam_email]
      role    = "roles/resourcemanager.projectIamAdmin"
      condition = {
        title       = "resman_delegated_grant"
        description = "Resource manager service account delegated grant."
        expression = format(
          "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly(['%s'])",
          "roles/serviceusage.serviceUsageConsumer"
        )
      }
    }
  }
  iam_bindings_additive = {
    serviceusage_resman = {
      member = module.tenant-automation-tf-resman-sa[each.key].iam_email
      role   = "roles/serviceusage.serviceUsageConsumer"
    }
    serviceusage_resman_r = {
      member = module.tenant-automation-tf-resman-r-sa[each.key].iam_email
      role   = "roles/serviceusage.serviceUsageViewer"
    }
  }
  depends_on = [module.tenant-automation-project]
}

# output files bucket

module "tenant-automation-tf-output-gcs" {
  source     = "../../../modules/gcs"
  for_each   = local.fast_tenants
  project_id = module.tenant-automation-project[each.key].project_id
  name       = "iac-core-outputs-0"
  prefix     = each.value.stage_0_prefix
  location   = each.value.locations.gcs
  versioning = true
}

# resource hierarchy stage's bucket and service account

module "tenant-automation-tf-resman-gcs" {
  source     = "../../../modules/gcs"
  for_each   = local.fast_tenants
  project_id = module.tenant-automation-project[each.key].project_id
  name       = "iac-core-resman-0"
  prefix     = each.value.stage_0_prefix
  location   = each.value.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [
      module.tenant-automation-tf-resman-sa[each.key].iam_email
    ]
    "roles/storage.objectViewer" = [
      module.tenant-automation-tf-resman-r-sa[each.key].iam_email
    ]
  }
}

module "tenant-automation-tf-resman-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.fast_tenants
  project_id   = module.tenant-automation-project[each.key].project_id
  name         = "resman-0"
  display_name = "Terraform stage 1 resman service account."
  prefix       = each.value.stage_0_prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  # we use additive IAM to allow tenant CI/CD SAs to impersonate it
  iam_bindings_additive = (
    lookup(local.cicd_repositories, each.key, null) == null ? {} : {
      cicd_token_creator = {
        member = module.tenant-automation-tf-cicd-sa[each.key].iam_email
        role   = "roles/iam.serviceAccountTokenCreator"
      }
    }
  )
  iam_storage_roles = {
    (module.tenant-automation-tf-output-gcs[each.key].name) = [
      "roles/storage.admin"
    ]
  }
}

module "tenant-automation-tf-resman-r-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.fast_tenants
  project_id   = module.tenant-automation-project[each.key].project_id
  name         = "resman-0r"
  display_name = "Terraform stage 1 resman service account (read-only)."
  prefix       = each.value.stage_0_prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  # we use additive IAM to allow tenant CI/CD SAs to impersonate it
  iam_bindings_additive = (
    lookup(local.cicd_repositories, each.key, null) == null ? {} : {
      cicd_token_creator = {
        member = module.automation-tf-cicd-r-sa[each.key].iam_email
        role   = "roles/iam.serviceAccountTokenCreator"
      }
    }
  )
  iam_storage_roles = {
    (module.tenant-automation-tf-output-gcs[each.key].name) = [
      var.custom_roles["storage_viewer"]
    ]
  }
}

# tenant-level stage 2 service accounts are created here so that we can
# grant permissions on the org or VPC SC policy

module "tenant-automation-tf-network-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.fast_tenants
  project_id   = module.tenant-automation-project[each.key].project_id
  name         = "resman-net-0"
  display_name = "Terraform resman networking service account."
  prefix       = each.value.stage_0_prefix
  iam_organization_roles = {
    (var.organization.id) = [
      var.custom_roles.tenant_network_admin
    ]
  }
}

module "tenant-automation-tf-security-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.fast_tenants
  project_id   = module.tenant-automation-project[each.key].project_id
  name         = "resman-sec-0"
  display_name = "Terraform resman security service account."
  prefix       = each.value.stage_0_prefix
}

module "tenant-automation-tf-security-r-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.fast_tenants
  project_id   = module.tenant-automation-project[each.key].project_id
  name         = "resman-sec-0r"
  display_name = "Terraform resman security service account (read-only)."
  prefix       = each.value.stage_0_prefix
}
