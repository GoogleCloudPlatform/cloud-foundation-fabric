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

# tfdoc:file:description Automation project and resources.

locals {
  cicd_resman_sa    = try(module.automation-tf-cicd-sa["resman"].iam_email, "")
  cicd_resman_r_sa  = try(module.automation-tf-cicd-r-sa["resman"].iam_email, "")
  cicd_tenants_sa   = try(module.automation-tf-cicd-sa["tenants"].iam_email, "")
  cicd_tenants_r_sa = try(module.automation-tf-cicd-r-sa["tenants"].iam_email, "")
  cicd_vpcsc_sa     = try(module.automation-tf-cicd-sa["vpcsc"].iam_email, "")
  cicd_vpcsc_r_sa   = try(module.automation-tf-cicd-r-sa["vpcsc"].iam_email, "")
}

module "automation-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "iac-core-0"
  parent = coalesce(
    var.project_parent_ids.automation, "organizations/${var.organization.id}"
  )
  prefix = local.prefix
  contacts = (
    var.bootstrap_user != null || var.essential_contacts == null
    ? {}
    : { (var.essential_contacts) = ["ALL"] }
  )
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
  org_policies = var.bootstrap_user != null ? {} : {
    "compute.skipDefaultNetworkCreation" = {
      rules = [{ enforce = true }]
    }
    "iam.automaticIamGrantsForDefaultServiceAccounts" = {
      rules = [{ enforce = true }]
    }
    "iam.disableServiceAccountKeyCreation" = {
      rules = [{ enforce = true }]
    }
  }
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
      "essentialcontacts.googleapis.com",
      "iam.googleapis.com",
      "iamcredentials.googleapis.com",
      "networksecurity.googleapis.com",
      "orgpolicy.googleapis.com",
      "pubsub.googleapis.com",
      "servicenetworking.googleapis.com",
      "serviceusage.googleapis.com",
      "stackdriver.googleapis.com",
      "storage-component.googleapis.com",
      "storage.googleapis.com",
      "sts.googleapis.com"
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
      ADMIN_READ = []
      # enable DATA_WRITE if you want to capture configuration changes
      # to IAM-related resources (roles, deny policies, service
      # accounts, identity pools, etc)
      # DATA_WRITE = []
    }
  }
}

# output files bucket

module "automation-tf-output-gcs" {
  source     = "../../../modules/gcs"
  project_id = module.automation-project.project_id
  name       = "iac-core-outputs-0"
  prefix     = local.prefix
  location   = local.locations.gcs
  versioning = true
  depends_on = [module.organization]
}

# this stage's bucket and service account

module "automation-tf-bootstrap-gcs" {
  source     = "../../../modules/gcs"
  project_id = module.automation-project.project_id
  name       = "iac-core-bootstrap-0"
  prefix     = local.prefix
  location   = local.locations.gcs
  versioning = true
  depends_on = [module.organization]
}

module "automation-tf-bootstrap-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = "bootstrap-0"
  display_name = "Terraform organization bootstrap service account."
  prefix       = local.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.automation-tf-cicd-sa["bootstrap"].iam_email, null)
    ])
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.admin"]
  }
}

module "automation-tf-bootstrap-r-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = "bootstrap-0r"
  display_name = "Terraform organization bootstrap service account (read-only)."
  prefix       = local.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.automation-tf-cicd-r-sa["bootstrap"].iam_email, null)
    ])
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
  name       = "iac-core-resman-0"
  prefix     = local.prefix
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
  name         = "resman-0"
  display_name = "Terraform stage 1 resman service account."
  prefix       = local.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  # we use additive IAM to allow tenant CI/CD SAs to impersonate it
  iam_bindings_additive = merge(
    local.cicd_resman_sa == "" ? {} : {
      cicd_token_creator_resman = {
        member = local.cicd_resman_sa
        role   = "roles/iam.serviceAccountTokenCreator"
      }
    },
    local.cicd_tenants_sa == "" ? {} : {
      cicd_token_creator_tenants = {
        member = local.cicd_tenants_sa
        role   = "roles/iam.serviceAccountTokenCreator"
      }
    }
  )
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.admin"]
  }
}

module "automation-tf-resman-r-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = "resman-0r"
  display_name = "Terraform stage 1 resman service account (read-only)."
  prefix       = local.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  # we use additive IAM to allow tenant CI/CD SAs to impersonate it
  iam_bindings_additive = merge(
    local.cicd_resman_r_sa == "" ? {} : {
      cicd_token_creator_resman = {
        member = local.cicd_resman_r_sa
        role   = "roles/iam.serviceAccountTokenCreator"
      }
    },
    local.cicd_tenants_r_sa == "" ? {} : {
      cicd_token_creator_tenants = {
        member = local.cicd_tenants_r_sa
        role   = "roles/iam.serviceAccountTokenCreator"
      }
    }
  )
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
  name       = "iac-core-vpcsc-0"
  prefix     = local.prefix
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
  name         = "vpcsc-0"
  display_name = "Terraform stage 1 vpcsc service account."
  prefix       = local.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  # we use additive IAM to allow tenant CI/CD SAs to impersonate it
  iam_bindings_additive = merge(
    {
      security_admins = {
        member = local.principals["gcp-security-admins"]
        role   = "roles/iam.serviceAccountTokenCreator"
      }
    },
    local.cicd_vpcsc_sa == "" ? {} : {
      cicd_token_creator_vpcsc = {
        member = local.cicd_vpcsc_sa
        role   = "roles/iam.serviceAccountTokenCreator"
      }
    }
  )
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.admin"]
  }
}

module "automation-tf-vpcsc-r-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = "vpcsc-0r"
  display_name = "Terraform stage 1 vpcsc service account (read-only)."
  prefix       = local.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  # we use additive IAM to allow tenant CI/CD SAs to impersonate it
  iam_bindings_additive = local.cicd_vpcsc_r_sa == "" ? {} : {
    cicd_token_creator_vpcsc = {
      member = local.cicd_vpcsc_r_sa
      role   = "roles/iam.serviceAccountTokenCreator"
    }
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = [module.organization.custom_role_id["storage_viewer"]]
  }
}
