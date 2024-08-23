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

locals {
  _cicd_configs = merge(
    {
      for k, v in var.fast_stage_2 :
      k => merge(v.cicd_config, { env = "prod", lvl = 2 })
      if v.cicd_config != null
    },
    {
      for k, v in var.fast_stage_3 :
      "${k}-prod" => merge(v.cicd_config, { env = "prod", short_name = k, lvl = 3 })
      if v.cicd_config != null
    },
    {
      for k, v in var.fast_stage_3 :
      "${k}-dev" => merge(v.cicd_config, { env = "dev", short_name = k, lvl = 3 })
      if v.cicd_config != null && v.folder_config.create_env_folders == true
    },
  )
  # filter by valid identity provider and type
  cicd_repositories = {
    for k, v in local._cicd_configs : k => v if(
      contains(keys(local.identity_providers), v.identity_provider) &&
      fileexists("${path.module}/templates/workflow-${v.repository.type}.yaml")
    )
  }
  cicd_workflow_files = {
    stage_2 = [
      "0-bootstrap.auto.tfvars.json",
      "1-resman.auto.tfvars.json",
      "0-globals.auto.tfvars.json"
    ]
    stage_3 = [
      for k, v in local._cicd_configs :
      "2-${k}.auto.tfvars" if v.lvl == 2
    ]
  }
}

module "cicd-sa-rw" {
  source     = "../../../modules/iam-service-account"
  for_each   = local.cicd_repositories
  project_id = var.automation.project_id
  name       = "${each.value.env}-resman-${each.value.short_name}-1"
  display_name = (
    "CI/CD ${each.value.lvl}-${each.value.short_name} ${each.value.env} service account."
  )
  prefix = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      each.value.repository.branch == null
      ? format(
        local.identity_providers[each.value.identity_provider].principal_repo,
        var.automation.federated_identity_pool,
        each.value.repository.name
      )
      : format(
        local.identity_providers[each.value.identity_provider].principal_branch,
        var.automation.federated_identity_pool,
        each.value.repository.name,
        each.value.repository.branch
      )
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

module "cicd-sa-ro" {
  source     = "../../../modules/iam-service-account"
  for_each   = local.cicd_repositories
  project_id = var.automation.project_id
  name       = "${each.value.env}-resman-${each.value.short_name}-1r"
  display_name = (
    "CI/CD ${each.value.lvl}-${each.value.short_name} ${each.value.env} service account (read-only)."
  )
  prefix = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      format(
        local.identity_providers[each.value.identity_provider].principal_repo,
        var.automation.federated_identity_pool,
        each.value.repository.name
      )
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}
