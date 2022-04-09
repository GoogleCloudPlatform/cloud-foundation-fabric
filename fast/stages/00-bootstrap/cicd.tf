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

# tfdoc:file:description Workload Identity Federation configurations for CI/CD.

locals {
  _cicd_config = coalesce(var.cicd_config, {
    providers    = null
    repositories = null
  })
  cicd_providers = {
    for k, v in coalesce(local._cicd_config.providers, {}) :
    k => merge(
      lookup(local.cicd_provider_defs, v.issuer, {}),
      { attribute_condition = v.attribute_condition, issuer = v.issuer }
    )
    if contains(keys(local.cicd_provider_defs), v.issuer)
  }
  cicd_repositories = {
    for k, v in coalesce(local._cicd_config.repositories, {}) : k => merge(
      v, { issuer = try(local.cicd_providers[v.provider].issuer, null) }
    )
    if v != null && contains(keys(local.cicd_providers), v.provider)
  }
  cicd_service_accounts = {
    for k, v in module.automation-tf-cicd-sa :
    k => v.iam_email
  }
}

# TODO: check in resman for the relevant org policy
#       constraints/iam.workloadIdentityPoolProviders

resource "google_iam_workload_identity_pool" "default" {
  provider                  = google-beta
  count                     = length(local.cicd_providers) > 0 ? 1 : 0
  project                   = module.automation-project.project_id
  workload_identity_pool_id = "${var.prefix}-bootstrap"
}

# https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform
# https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#configuring-the-oidc-trust-with-the-cloud

resource "google_iam_workload_identity_pool_provider" "default" {
  provider = google-beta
  for_each = local.cicd_providers
  project  = module.automation-project.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default.0.workload_identity_pool_id
  )
  workload_identity_pool_provider_id = "${var.prefix}-bootstrap-${each.key}"
  attribute_condition                = each.value.attribute_condition
  attribute_mapping                  = each.value.attribute_mapping
  oidc {
    issuer_uri = each.value.issuer_uri
  }
}

module "automation-tf-cicd-sa" {
  source      = "../../../modules/iam-service-account"
  for_each    = local.cicd_repositories
  project_id  = module.automation-project.project_id
  name        = "${each.key}-1"
  description = "Terraform CI/CD stage 1 ${each.key} service account."
  prefix      = local.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      each.value.branch == null
      ? format(
        local.cicd_providers[each.value.provider].principalset_tpl,
        google_iam_workload_identity_pool.default.0.name,
        each.value.name
      )
      : format(
        local.cicd_providers[each.value.provider].principal_tpl,
        each.value.name,
        each.value.branch
      )
    ]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.objectViewer"]
  }
}
