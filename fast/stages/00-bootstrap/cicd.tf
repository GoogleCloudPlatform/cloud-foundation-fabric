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

locals {
  _cicd_subject = {
    GITHUB = local.cicd_provider != "GITHUB" ? null : join(":", [
      "repo",
      var.cicd_config.repositories.resman.name,
      "ref",
      var.cicd_config.repositories.resman.branch
    ])
    GITLAB = local.cicd_provider != "GITHUB" ? null : join(":", [

    ])
  }
  cicd_enabled = local.cicd_provider != null
  cicd_principal = !local.cicd_enabled ? null : join("/", [
    "principal://iam.googleapis.com",
    google_iam_workload_identity_pool.default.0.name,
    "subject",
    lookup(local._cicd_subject, local.cicd_provider, "")
  ])
  cicd_provider = try(var.cicd_config.provider, null)
  cicd_sa = !local.cicd_enabled ? [] : [
    module.automation-tf-resman-sa-cicd.0.iam_email
  ]
}

# TODO: check in resman for the relevant org policy
#       constraints/iam.workloadIdentityPoolProviders
# TODO: optionally create and configure repositories
# TODO: use a GCS bucket for output files
# TODO: include pipeline configuration files in output files

resource "google_iam_workload_identity_pool" "default" {
  provider                  = google-beta
  count                     = local.cicd_enabled ? 1 : 0
  project                   = module.automation-project.project_id
  workload_identity_pool_id = "${var.prefix}-default"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  provider = google-beta
  count    = local.cicd_provider == "GITHUB" ? 1 : 0
  project  = module.automation-project.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default.0.workload_identity_pool_id
  )
  workload_identity_pool_provider_id = "${var.prefix}-default-github"
  # TODO: limit via attribute_condition?
  attribute_mapping = {
    "google.subject"  = "assertion.sub"
    "attribute.sub"   = "assertion.sub"
    "attribute.actor" = "assertion.actor"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_iam_workload_identity_pool_provider" "gitlab" {
  provider = google-beta
  count    = local.cicd_provider == "GITLAB" ? 1 : 0
  project  = module.automation-project.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default.0.workload_identity_pool_id
  )
  workload_identity_pool_provider_id = "${var.prefix}-default-gitlab"
  # TODO: limit via attribute_condition?
  attribute_mapping = {
    "google.subject" = "assertion.sub"
    "attribute.sub"  = "assertion.sub"
  }
  oidc {
    allowed_audiences = ["https://gitlab.com"]
    issuer_uri        = "https://gitlab.com"
  }
}

module "automation-tf-resman-sa-cicd" {
  source      = "../../../modules/iam-service-account"
  count       = local.cicd_enabled ? 1 : 0
  project_id  = module.automation-project.project_id
  name        = "resman-1"
  description = "Terraform CI/CD stage 1 resman service account."
  prefix      = local.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [local.cicd_principal]
  }
}
