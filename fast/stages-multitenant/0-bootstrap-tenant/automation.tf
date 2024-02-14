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

# tfdoc:file:description Tenant automation project and resources.

module "automation-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "iac-core-0"
  parent = coalesce(
    var.project_parent_ids.automation,
    module.tenant-folder.id
  )
  prefix = local.prefix
  # human (groups) IAM bindings
  group_iam = {
    (local.groups.gcp-admins) = [
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountTokenCreator",
    ]
    (local.groups.gcp-admins) = [
      "roles/iam.serviceAccountTokenCreator",
      "roles/iam.workloadIdentityPoolAdmin"
    ]
  }
  # machine (service accounts) IAM bindings
  iam = {
    "roles/owner" = [
      module.automation-tf-resman-sa.iam_email,
      "serviceAccount:${local.resman_sa}"
    ]
    "roles/cloudbuild.builds.editor" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/iam.serviceAccountAdmin" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/iam.workloadIdentityPoolAdmin" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/source.admin" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/storage.admin" = [
      module.automation-tf-resman-sa.iam_email
    ]
  }
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

# output files bucket

module "automation-tf-output-gcs" {
  source        = "../../../modules/gcs"
  project_id    = module.automation-project.project_id
  name          = "iac-core-outputs-0"
  prefix        = local.prefix
  location      = local.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
}

# resource management stage bucket and service account

module "automation-tf-resman-gcs" {
  source        = "../../../modules/gcs"
  project_id    = module.automation-project.project_id
  name          = "iac-core-resman-0"
  prefix        = local.prefix
  location      = local.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [module.automation-tf-resman-sa.iam_email]
  }
}

module "automation-tf-resman-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = "resman-0"
  display_name = "Terraform stage 1 resman service account."
  prefix       = local.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.automation-tf-cicd-sa-resman["0"].iam_email, null)
    ])
  }
  iam_billing_roles = local.billing_mode == "resource" ? {
    (var.billing_account.id) = [
      "roles/billing.admin", "roles/billing.costsManager"
    ]
  } : {}
  iam_organization_roles = local.billing_mode == "org" ? {
    (var.organization.id) = [
      "roles/billing.admin", "roles/billing.costsManager"
    ]
  } : {}
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.admin"]
  }
}
