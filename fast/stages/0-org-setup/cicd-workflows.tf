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
  _cicd_workflows = try(yamldecode(file(local.paths.cicd_workflows)), {})
  # dereferencing maps
  cicd_ctx_sa = {
    for k, v in merge(local.ctx.iam_principals, module.factory.iam_principals) :
    "$iam_principals:${k}" => v
  }
  cicd_ctx_wif = {
    for k, v in merge(
      local.ctx.workload_identity_providers,
      local.workload_identity_providers
    ) : "$workload_identity_providers:${k}" => v
  }
  cicd_ctx_wif_pools = {
    for k, v in merge(
      local.ctx.workload_identity_pools,
      local.workload_identity_pools
    ) : "$workload_identity_pools:${k}" => v
  }
  # normalize workflow configurations, correctness is checked via preconditions
  cicd_workflows = {
    for k, v in local._cicd_workflows : k => {
      provider_files = {
        apply = try(v.provider_files.apply, null)
        plan  = try(v.provider_files.plan, null)
      }
      repository = {
        apply_branches = try(v.repository.apply_branches, [])
        name           = try(v.repository.name, null)
        type           = try(v.repository.type, null)
      }
      service_accounts = {
        apply = try(
          trimprefix(
            local.cicd_ctx_sa[v.service_accounts.apply], "serviceAccount:"
          ),
          v.service_accounts.apply,
          null
        )
        plan = try(
          trimprefix(
            local.cicd_ctx_sa[v.service_accounts.plan], "serviceAccount:"
          ),
          v.service_accounts.plan,
          null
        )
      }
      tfvars_files = try(v.tfvars_files, [])
      workload_identity = {
        pool = try(
          local.cicd_ctx_wif_pools[v.workload_identity.pool],
          v.workload_identity.pool,
          null
        )
        provider = try(
          local.cicd_ctx_wif[v.workload_identity.provider],
          v.workload_identity.provider,
          null
        )
        iam_principalsets = try(
          local.wif_iam_templates[v.workload_identity.iam_principalsets.template],
          {
            apply = try(v.workload_identity.iam_principalsets.apply)
            plan  = try(v.workload_identity.iam_principalsets.plan)
          }
        )
        audiences = try(v.workload_identity.audiences, [])
      }
    }
  }
  # generate workflow files contents
  cicd_workflows_contents = {
    for k, v in local.cicd_workflows : k => templatefile(
      "assets/workflow-${v.repository.type}.yaml", merge(v, {
        outputs_bucket             = local.of_outputs_bucket
        stage_name                 = k
        workload_identity_provider = v.workload_identity.provider
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
          each.value.workload_identity.iam_principalsets.plan,
          each.value.workload_identity.pool,
          each.value.repository.name
        )
      ]
      : [
        for v in each.value.repository.apply_branches : format(
          each.value.workload_identity.iam_principalsets.apply,
          each.value.workload_identity.pool,
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
        each.value.workload_identity.iam_principalsets.plan,
        each.value.workload_identity.pool,
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
  for_each       = local.output_files.storage_bucket == null ? {} : local.cicd_workflows_contents
  bucket         = local.of_outputs_bucket
  name           = "workflows/${each.key}.yaml"
  content        = each.value
  source_md5hash = md5(each.value)
}
