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

# tfdoc:file:description CI/CD resources for individual teams.

# source repository

module "branch-teams-team-cicd-repo" {
  source = "../../../modules/source-repository"
  for_each = {
    for k, v in coalesce(local.team_cicd_repositories, {}) : k => v
    if v.cicd.type == "sourcerepo"
  }
  project_id = var.automation.project_id
  name       = each.value.cicd.name
  iam = {
    "roles/source.admin"  = [module.branch-teams-team-sa[each.key].iam_email]
    "roles/source.reader" = [module.branch-teams-team-sa-cicd[each.key].iam_email]
  }
  triggers = {
    "fast-03-team-${each.key}" = {
      filename        = ".cloudbuild/workflow.yaml"
      included_files  = ["**/*tf", ".cloudbuild/workflow.yaml"]
      service_account = module.branch-teams-team-sa-cicd[each.key].id
      substitutions   = {}
      template = {
        project_id  = null
        branch_name = each.value.cicd.branch
        repo_name   = each.value.cicd.name
        tag_name    = null
      }
    }
  }
  depends_on = [module.branch-teams-team-sa-cicd]
}

# SA used by CI/CD workflows to impersonate automation SAs

module "branch-teams-team-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    try(local.team_cicd_repositories, null) != null
    ? local.team_cicd_repositories
    : {}
  )
  project_id   = var.automation.project_id
  name         = "prod-teams-${each.key}-1"
  display_name = "Terraform CI/CD team ${each.key} service account."
  prefix       = var.prefix
  iam = (
    each.value.cicd.type == "sourcerepo"
    # used directly from the cloud build trigger for source repos
    ? {
      "roles/iam.serviceAccountUser" = local.automation_resman_sa_iam
    }
    # impersonated via workload identity federation for external repos
    : {
      "roles/iam.workloadIdentityUser" = [
        each.value.cicd.branch == null
        ? format(
          local.identity_providers[each.value.cicd.identity_provider].principalset_tpl,
          var.automation.federated_identity_pool,
          each.value.cicd.name
        )
        : format(
          local.identity_providers[each.value.cicd.identity_provider].principal_tpl,
          var.automation.federated_identity_pool,
          each.value.cicd.name,
          each.value.cicd.branch
        )
      ]
    }
  )
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}
