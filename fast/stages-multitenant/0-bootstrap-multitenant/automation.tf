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

# tfdoc:file:description Tenant automation project and resources.

locals {
  automation_sa_roles = {
    for k in setproduct(keys(var.tenant_configs), [
      "roles/cloudbuild.builds.editor",
      "roles/source.admin",
      "roles/storage.admin"
    ]) : "${k.0}/${k.1}" => { tenant = k.0, role = k.1 }
  }
  automation_shared_roles = {
    for k in setproduct(keys(var.tenant_configs), [
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountTokenCreator",
      "roles/iam.workloadIdentityPoolAdmin"
    ]) : "${k.0}/${k.1}" => { tenant = k.0, role = k.1 }
  }
}

module "automation-project" {
  source          = "../../../modules/project"
  for_each        = var.tenant_configs
  billing_account = var.billing_account.id
  name            = "iac-core-0"
  parent = coalesce(
    each.value.project_parent_ids.automation,
    module.tenant-folder[each.key].id
  )
  prefix = local.prefixes[each.key]
  # # human (groups) IAM bindings
  # group_iam = {
  #   (local.groups[each.key].gcp-admins) = [
  #     "roles/iam.serviceAccountAdmin",
  #     "roles/iam.serviceAccountTokenCreator",
  #     "roles/iam.workloadIdentityPoolAdmin"
  #   ]
  # }
  # # machine (service accounts) IAM bindings
  # iam = {
  #   "roles/owner" = [
  #     module.automation-tf-resman-sa[each.key].iam_email
  #   ]
  #   "roles/cloudbuild.builds.editor" = [
  #     module.automation-tf-resman-sa[each.key].iam_email
  #   ]
  #   "roles/iam.serviceAccountAdmin" = [
  #     module.automation-tf-resman-sa[each.key].iam_email
  #   ]
  #   "roles/iam.workloadIdentityPoolAdmin" = [
  #     module.automation-tf-resman-sa[each.key].iam_email
  #   ]
  #   "roles/source.admin" = [
  #     module.automation-tf-resman-sa[each.key].iam_email
  #   ]
  #   "roles/storage.admin" = [
  #     module.automation-tf-resman-sa[each.key].iam_email
  #   ]
  # }
  services = [
    "accesscontextmanager.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "essentialcontacts.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "orgpolicy.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "sourcerepo.googleapis.com",
    "stackdriver.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com"
  ]
}

# use resources for project IAM bindings to avoid a loop with service account

resource "google_project_iam_binding" "automation-iam-shared" {
  for_each = local.automation_shared_roles
  project  = module.automation-project[each.value.tenant].project_id
  role     = each.value.role
  members = [
    "group:${local.groups[each.value.tenant].gcp-admins}",
    module.automation-tf-resman-sa[each.value.tenant].iam_email
  ]
}

resource "google_project_iam_binding" "automation-iam-sa" {
  for_each = local.automation_sa_roles
  project  = module.automation-project[each.value.tenant].project_id
  role     = each.value.role
  members = [
    module.automation-tf-resman-sa[each.value.tenant].iam_email
  ]
}

# output files bucket

module "automation-tf-output-gcs" {
  source     = "../../../modules/gcs"
  for_each   = var.tenant_configs
  project_id = module.automation-project[each.key].project_id
  name       = "iac-core-outputs-0"
  prefix     = local.prefixes[each.key]
  location   = local.locations[each.key].gcs
  versioning = true
}

# resource management stage bucket and service account

module "automation-tf-resman-gcs" {
  source     = "../../../modules/gcs"
  for_each   = var.tenant_configs
  project_id = module.automation-project[each.key].project_id
  name       = "iac-core-resman-0"
  prefix     = local.prefixes[each.key]
  location   = local.locations[each.key].gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.automation-tf-resman-sa[each.key].iam_email]
  }
}

module "automation-tf-resman-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = var.tenant_configs
  project_id   = module.automation-project[each.key].project_id
  name         = "resman-0"
  display_name = "Terraform stage 1 resman service account."
  prefix       = local.prefixes[each.key]
  # allow SA used by CI/CD workflow to impersonate this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.automation-tf-cicd-sa[each.key].iam_email, null)
    ])
  }
  iam_billing_roles = !var.billing_account.is_org_level ? {
    (var.billing_account.id) = [
      "roles/billing.admin", "roles/billing.costsManager"
    ]
  } : {}
  iam_organization_roles = var.billing_account.is_org_level ? {
    (var.organization.id) = [
      "roles/billing.admin", "roles/billing.costsManager"
    ]
  } : {}
  iam_storage_roles = {
    (module.automation-tf-output-gcs[each.key].name) = ["roles/storage.admin"]
  }
}
