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

# tfdoc:file:description Automation project and resources.

module "automation-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = var.resource_names["project-automation"]
  parent = coalesce(
    var.project_parent_ids.automation, "organizations/${var.organization.id}"
  )
  prefix   = var.prefix
  universe = var.universe
  contacts = (
    var.bootstrap_user != null || var.essential_contacts == null
    ? {}
    : { (var.essential_contacts) = ["ALL"] }
  )
  factories_config = {
    org_policies = (
      var.bootstrap_user != null ? null : var.factories_config.org_policies_iac
    )
  }
  # human (groups) IAM bindings
  iam_by_principals = {
    (local.principals.gcp-devops) = [
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountTokenCreator",
    ]
    (local.principals.gcp-organization-admins) = [
      "roles/iam.serviceAccountTokenCreator",
      "roles/iam.workloadIdentityPoolAdmin"
    ]
  }
  # machine (service accounts) IAM bindings
  iam = {
    "roles/browser" = [
      module.automation-tf-resman-r-sa.iam_email
    ]
    "roles/owner" = [
      module.automation-tf-bootstrap-sa.iam_email
    ]
    "roles/cloudbuild.builds.editor" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/cloudbuild.builds.viewer" = [
      module.automation-tf-resman-r-sa.iam_email
    ]
    "roles/iam.serviceAccountAdmin" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/iam.serviceAccountViewer" = [
      module.automation-tf-resman-r-sa.iam_email
    ]
    "roles/iam.workloadIdentityPoolAdmin" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/iam.workloadIdentityPoolViewer" = [
      module.automation-tf-resman-r-sa.iam_email
    ]
    "roles/source.admin" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/source.reader" = [
      module.automation-tf-resman-r-sa.iam_email
    ]
    "roles/storage.admin" = [
      module.automation-tf-resman-sa.iam_email
    ]
    (module.organization.custom_role_id["storage_viewer"]) = [
      module.automation-tf-bootstrap-r-sa.iam_email,
      module.automation-tf-resman-r-sa.iam_email
    ]
    "roles/viewer" = [
      module.automation-tf-bootstrap-r-sa.iam_email,
      module.automation-tf-resman-r-sa.iam_email
    ]
  }
  iam_bindings = {
    delegated_grants_resman = {
      members = [module.automation-tf-resman-sa.iam_email]
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
      member = module.automation-tf-resman-sa.iam_email
      role   = "roles/serviceusage.serviceUsageConsumer"
    }
    serviceusage_resman_r = {
      member = module.automation-tf-resman-r-sa.iam_email
      role   = "roles/serviceusage.serviceUsageViewer"
    }
  }
  org_policies = (
    var.bootstrap_user != null || var.org_policies_config.iac_policy_member_domains == null
    ? {}
    : {
      "iam.allowedPolicyMemberDomains" = {
        inherit_from_parent = true
        rules = [{
          allow = {
            values = var.org_policies_config.iac_policy_member_domains
          }
        }]
      }
    }
  )
  services = concat(
    [
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
      "datacatalog.googleapis.com",
      "essentialcontacts.googleapis.com",
      "iam.googleapis.com",
      "iamcredentials.googleapis.com",
      "logging.googleapis.com",
      "monitoring.googleapis.com",
      "networksecurity.googleapis.com",
      "orgpolicy.googleapis.com",
      "pubsub.googleapis.com",
      "servicenetworking.googleapis.com",
      "serviceusage.googleapis.com",
      "storage-component.googleapis.com",
      "storage.googleapis.com",
      "sts.googleapis.com",
    ],
    # enable specific service only after org policies have been applied
    var.bootstrap_user != null ? [] : [
      "cloudbuild.googleapis.com",
      "compute.googleapis.com",
      "container.googleapis.com",
    ]
  )
  # Enable IAM data access logs to capture impersonation and service
  # account token generation events. This is implemented within the
  # automation project to limit log volume. For heightened security,
  # consider enabling it at the organization level. A log sink within
  # the organization will collect and store these logs in a logging
  # bucket. See
  # https://cloud.google.com/iam/docs/audit-logging#audited_operations
  logging_data_access = {
    "iam.googleapis.com" = {
      # ADMIN_READ captures impersonation and token generation/exchanges
      ADMIN_READ = {}
      # enable DATA_WRITE if you want to capture configuration changes
      # to IAM-related resources (roles, deny policies, service
      # accounts, identity pools, etc)
      # DATA_WRITE = {}
    }
  }
}

# output files bucket

module "automation-tf-output-gcs" {
  source     = "../../../modules/gcs"
  project_id = module.automation-project.project_id
  name       = var.resource_names["gcs-outputs"]
  prefix     = var.prefix
  location   = local.locations.gcs
  versioning = true
  depends_on = [module.organization]
}

# this stage's bucket and service account

module "automation-tf-bootstrap-gcs" {
  source     = "../../../modules/gcs"
  project_id = module.automation-project.project_id
  name       = var.resource_names["gcs-bootstrap"]
  prefix     = var.prefix
  location   = local.locations.gcs
  versioning = true
  depends_on = [module.organization]
}

module "automation-tf-bootstrap-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = var.resource_names["sa-bootstrap"]
  display_name = "Terraform organization bootstrap service account."
  prefix       = var.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      for k, v in local.cicd_repositories :
      module.automation-tf-cicd-sa[k].iam_email if v.stage == "bootstrap"
    ]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.admin"]
  }
}

module "automation-tf-bootstrap-r-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = var.resource_names["sa-bootstrap_ro"]
  display_name = "Terraform organization bootstrap service account (read-only)."
  prefix       = var.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      for k, v in local.cicd_repositories :
      module.automation-tf-cicd-r-sa[k].iam_email if v.stage == "bootstrap"
    ]
  }
  # we grant organization roles here as IAM bindings have precedence over
  # custom roles in the organization module, so these need to depend on it
  iam_organization_roles = {
    (var.organization.id) = [
      module.organization.custom_role_id["organization_admin_viewer"],
      module.organization.custom_role_id["tag_viewer"]
    ]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = [module.organization.custom_role_id["storage_viewer"]]
  }
}

# resource hierarchy stage's bucket and service account

module "automation-tf-resman-gcs" {
  source     = "../../../modules/gcs"
  project_id = module.automation-project.project_id
  name       = var.resource_names["gcs-resman"]
  prefix     = var.prefix
  location   = local.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.automation-tf-resman-sa.iam_email]
    "roles/storage.objectViewer" = [module.automation-tf-resman-r-sa.iam_email]
  }
  depends_on = [module.organization]
}

module "automation-tf-resman-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = var.resource_names["sa-resman"]
  display_name = "Terraform stage 1 resman service account."
  prefix       = var.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      for k, v in local.cicd_repositories :
      module.automation-tf-cicd-sa[k].iam_email if v.stage == "resman"
    ]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.admin"]
  }
}

module "automation-tf-resman-r-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = var.resource_names["sa-resman_ro"]
  display_name = "Terraform stage 1 resman service account (read-only)."
  prefix       = var.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      for k, v in local.cicd_repositories :
      module.automation-tf-cicd-r-sa[k].iam_email if v.stage == "resman"
    ]
  }
  # we grant organization roles here as IAM bindings have precedence over
  # custom roles in the organization module, so these need to depend on it
  iam_organization_roles = {
    (var.organization.id) = [
      module.organization.custom_role_id["organization_admin_viewer"],
      module.organization.custom_role_id["tag_viewer"]
    ]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = [module.organization.custom_role_id["storage_viewer"]]
  }
}

# VPC SC stage's bucket and service account

module "automation-tf-vpcsc-gcs" {
  source     = "../../../modules/gcs"
  project_id = module.automation-project.project_id
  name       = var.resource_names["gcs-vpcsc"]
  prefix     = var.prefix
  location   = local.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.automation-tf-vpcsc-sa.iam_email]
    "roles/storage.objectViewer" = [module.automation-tf-vpcsc-r-sa.iam_email]
  }
  depends_on = [module.organization]
}

module "automation-tf-vpcsc-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = var.resource_names["sa-vpcsc"]
  display_name = "Terraform stage 1 vpcsc service account."
  prefix       = var.prefix
  # allow security group and SA used by CI/CD workflow to impersonate this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      [local.principals["gcp-security-admins"]],
      [
        for k, v in local.cicd_repositories :
        module.automation-tf-cicd-sa[k].iam_email if v.stage == "vpcsc"
      ]
    )
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.admin"]
  }
}

module "automation-tf-vpcsc-r-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = var.resource_names["sa-vpcsc_ro"]
  display_name = "Terraform stage 1 vpcsc service account (read-only)."
  prefix       = var.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      for k, v in local.cicd_repositories :
      module.automation-tf-cicd-r-sa[k].iam_email if v.stage == "vpcsc"
    ]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = [module.organization.custom_role_id["storage_viewer"]]
  }
}
