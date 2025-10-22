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
  # dereferencing maps
  _cicd_ctx_wif = {
    for k, v in google_iam_workload_identity_pool_provider.default :
    "$wif_providers:${k}" => v.name
  }
  _cicd_ctx_sa = {
    for k, v in merge(local.ctx.iam_principals, module.factory.iam_principals) :
    "$iam_principals:${k}" => v
  }
  # normalized workflows
  _cicd_workflows = {
    for k, v in lookup(local.cicd, "workflows", {}) : k => {
      provider_files = {
        apply = try(v.provider_files.apply, null)
        plan  = try(v.provider_files.apply, null)
      }
      repository = {
        name           = try(v.repository.name, null)
        type           = try(v.repository.type, null)
        apply_branches = try(v.repository.apply_branches, [])
      }
      service_accounts = {
        apply = try(v.service_accounts.apply, null)
        plan  = try(v.service_accounts.apply, null)
      }
      tfvars_files = try(v.tfvars_files, [])
      wif = {
        id = try(
          local._cicd_ctx_wif[v.workload_identity_provider.id],
          v.workload_identity_provider.id,
          null
        )
        audiences = try(v.workload_identity_provider.audiences, [])
      }
    } if contains(["github", "gitlab"], try(v.repository.type, "-"))
  }
  # raw configuration (shared to the wif files)
  cicd = try(yamldecode(file(local.paths.cicd)), {})
  # iam bindings for service accounts
  # cicd_iam = flatten([
  #   for k, v in local.cicd_workflows : concat(
  #     v.iam_principals.apply == null
  #     # apply with no branches, use plan principalset
  #     ? [
  #       {
  #         key             = "${k}-apply"
  #         principal       = format(v.iam_principals.plan, v.wif.id, v.repository.name)
  #         service_account = v.service_accounts.apply
  #       }
  #     ]
  #     # apply with branches, one apply principal per branch
  #     : [
  #       for b in v.repository.apply_branches : {
  #         key             = "${k}-apply-${b}"
  #         principal       = format(v.iam_principals.apply, v.wif.id, v.repository.name, b)
  #         service_account = v.service_accounts.apply
  #       }
  #     ],
  #     # plan
  #     [
  #       {
  #         key             = "${k}-plan"
  #         principal       = format(v.iam_principals.plan, v.wif.id, v.repository.name)
  #         service_account = v.service_accounts.plan
  #       }
  #     ]
  #   )
  # ])
  # workflows configuration
  cicd_workflows = {
    for k, v in local._cicd_workflows : k => merge(v, {
      iam_principals = {
        apply = (
          length(v.repository.apply_branches) > 0
          ? local.wif_defs[v.repository.type].principal_branch
          : null
        )
        plan = local.wif_defs[v.repository.type].principal_repo
      }
      service_accounts = {
        apply = try(
          local._cicd_ctx_sa[v.service_accounts.apply], v.service_accounts.apply
        )
        plan = try(
          local._cicd_ctx_sa[v.service_accounts.plan], v.service_accounts.plan
        )
      }
    })
    if(
      v.provider_files.apply != null && v.provider_files.plan != null &&
      v.repository.name != null && v.wif.id != null &&
      v.service_accounts.apply != null && v.service_accounts.plan != null
    )
  }
}


# resource "google_service_account_iam_member" "cicd_sa" {
#   for_each           = { for v in local.cicd_iam : v.key => v }
#   service_account_id = trimprefix(each.value.service_account, "serviceAccount:")
#   role               = "roles/iam.workloadIdentityUser"
#   member             = each.value.principal
# }


# module "cicd-sa-plan" {
#   source   = "../../../modules/iam-service-account"
#   for_each = { for k, v in local.cicd_workflows : k => v if v._is_valid }
#   name     = v.service_accounts.plan
#   service_account_reuse = {
#     use_data_source = false
#   }
#   iam_bindings_additive = {
#     cicd_wif_user = {
#       member = format(
#         v.iam_principals.plan,
#         v.workload_identity_provider.id,
#         v.repository.name
#       )
#       role = "roles/iam.workloadIdentityUser"
#     }
#   }
# }

# resource "local_file" "workflows" {
#   for_each        = local.of_path == null ? {} : local.cicd_workflows_files
#   file_permission = "0644"
#   filename        = "${local.of_path}/workflows/${each.key}.yaml"
#   content         = each.value.workflow
# }

# resource "google_storage_bucket_object" "workflows" {
#   for_each = local.cicd_workflows_files
#   bucket   = each.value.outputs_bucket
#   name     = "workflows/${each.key}.yaml"
#   content  = each.value.workflow
# }
