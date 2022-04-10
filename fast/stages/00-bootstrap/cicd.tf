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
  # TODO: map null provider to Cloud Build once we add support for it
  cicd_repositories = {
    for k, v in coalesce(var.cicd_repositories, {}) : k => merge(v, {
      issuer = try(
        local.identity_providers[v.identity_provider].issuer, null
      )
      principal_tpl = try(
        local.identity_providers[v.identity_provider].principal_tpl, null
      )
      principalset_tpl = try(
        local.identity_providers[v.identity_provider].principalset_tpl, null
      )
    })
    if v != null && contains(keys(local.identity_providers), v.identity_provider)
  }
  cicd_service_accounts = {
    for k, v in module.automation-tf-cicd-sa :
    k => v.iam_email
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
        each.value.principalset_tpl,
        google_iam_workload_identity_pool.default.0.name,
        each.value.name
      )
      : format(
        each.value.principal_tpl,
        each.value.name,
        each.value.branch
      )
    ]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.objectViewer"]
  }
}
