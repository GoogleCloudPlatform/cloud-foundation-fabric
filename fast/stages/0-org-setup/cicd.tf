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

locals {
  # raw configuration (the wif files are also users of this local)
  cicd = try(yamldecode(file(local.paths.cicd)), {})
  # dereferencing maps
  cicd_ctx_sa = {
    for k, v in merge(local.ctx.iam_principals, module.factory.iam_principals) :
    "$iam_principals:${k}" => v
  }
  cicd_ctx_wif = try({
    "$wif_pools:${local.wif_pool_name}" = google_iam_workload_identity_pool.default[0].name
  }, {})
  # normalize workflow configurations
  cicd_workflows = {
    for k, v in lookup(local.cicd, "workflows", {}) : k => merge(v, {
      iam_principal_templates = {
        branch = local.wif_defs[v.repository.type].principal_branch
        repo   = local.wif_defs[v.repository.type].principal_repo
      }
      repository = merge(v.repository, {
        apply_branches = try(v.repository.apply_branches, [])
      })
      service_accounts = {
        apply = trimprefix(try(
          local.cicd_ctx_sa[v.service_accounts.apply], v.service_accounts.apply
        ), "serviceAccount:")
        plan = trimprefix(try(
          local.cicd_ctx_sa[v.service_accounts.plan], v.service_accounts.plan
        ), "serviceAccount:")
      }
      workload_identity = {
        audiences = try(v.workload_identity.audiences, [])
        pool_id = try(
          local.cicd_ctx_wif[v.workload_identity.pool_id],
          v.workload_identity.pool_id
        )
      }
    })
    if(
      try(local.wif_defs[v.repository.type], null) != null &&
      try(v.provider_files.apply, null) != null &&
      try(v.provider_files.plan, null) != null &&
      try(v.repository.name, null) != null &&
      try(v.service_accounts.apply, null) != null &&
      try(v.service_accounts.plan, null) != null &&
      try(v.workload_identity.pool_id, null) != null
    )
  }
  # generate workflow files contents
  cicd_workflows_contents = {
    for k, v in local.cicd_workflows : k => templatefile(
      "assets/workflow-${v.repository.type}.yaml", merge(v, {
        outputs_bucket = local.of_outputs_bucket
        stage_name     = k
      })
    )
  }
}

module "cicd-sa-apply" {
  source   = "../../../modules/iam-service-account"
  for_each = local.cicd_workflows
  name     = each.value.service_accounts.apply
  service_account_reuse = {
    use_data_source = false
  }
  iam = {
    "roles/iam.workloadIdentityUser" = (
      length(each.value.repository.apply_branches) == 0
      ? [
        format(
          each.value.iam_principal_templates.repo,
          each.value.workload_identity.pool_id,
          each.value.repository.name
        )
      ]
      : [
        for v in each.value.repository.apply_branches : format(
          each.value.iam_principal_templates.branch,
          each.value.workload_identity.pool_id,
          each.value.repository.name,
          v
        )
      ]
    )
  }
}

module "cicd-sa-plan" {
  source   = "../../../modules/iam-service-account"
  for_each = local.cicd_workflows
  name     = each.value.service_accounts.plan
  service_account_reuse = {
    use_data_source = false
  }
  iam = {
    "roles/iam.workloadIdentityUser" = [
      format(
        each.value.iam_principal_templates.repo,
        each.value.workload_identity.pool_id,
        each.value.repository.name
      )
    ]
  }
}

resource "local_file" "workflows" {
  for_each        = local.of_path == null ? {} : local.cicd_workflows_contents
  file_permission = "0644"
  filename        = "${local.of_path}/workflows/${each.key}.yaml"
  content         = each.value
}

resource "google_storage_bucket_object" "workflows" {
  for_each = local.output_files.storage_bucket == null ? {} : local.cicd_workflows_contents
  bucket   = local.of_outputs_bucket
  name     = "workflows/${each.key}.yaml"
  content  = each.value
}
