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

# tfdoc:file:description CI/CD locals and resources.

locals {
  _cicd_configs = merge(
    # stage 2
    {
      for k, v in local.stage2 : k => merge(v.cicd_config, {
        env        = "prod"
        level      = 2
        stage      = replace(k, "_", "-")
        short_name = v.short_name
      }) if v.cicd_config != null
    },
    # stage 3
    {
      for k, v in local.stage3 : k => merge(v.cicd_config, {
        env        = v.environment
        level      = 3
        short_name = coalesce(v.short_name, k)
        stage      = replace(k, "_", "-")
      }) if v.cicd_config != null
    },
    # addons
    {
      for k, v in var.fast_addon : k => merge(v.cicd_config, {
        env        = "prod"
        level      = 2
        short_name = k
        stage      = substr(v.parent_stage, 2, -1)
      }) if v.cicd_config != null
    }
  )
  # finalize configurations and filter by valid identity provider and type
  cicd_repositories = {
    for k, v in local._cicd_configs : k => v if(
      contains(keys(local.identity_providers), v.identity_provider) &&
      fileexists("${path.module}/templates/workflow-${v.repository.type}.yaml")
    )
  }
  cicd_workflow_providers = merge(
    {
      for k, v in local.cicd_repositories :
      k => "${v.level}-${k}-providers.tf"
    },
    {
      for k, v in local.cicd_repositories :
      "${k}-r" => "${v.level}-${k}-r-providers.tf"
    }
  )
}

module "cicd-sa-rw" {
  source     = "../../../modules/iam-service-account"
  for_each   = local.cicd_repositories
  project_id = var.automation.project_id
  name = templatestring(var.resource_names["sa-cicd_rw"], {
    name = each.value.short_name
  })
  display_name = (
    "CI/CD ${each.value.level}-${each.value.short_name} ${each.value.env} service account."
  )
  prefix = "${var.prefix}-${var.environments[each.value.env].short_name}"
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
  name = templatestring(var.resource_names["sa-cicd_ro"], {
    name = each.value.short_name
  })
  display_name = (
    "CI/CD ${each.value.level}-${each.value.short_name} ${each.value.env} service account (read-only)."
  )
  prefix = "${var.prefix}-${var.environments[each.value.env].short_name}"
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
