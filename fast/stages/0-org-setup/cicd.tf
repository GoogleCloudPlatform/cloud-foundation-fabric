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
    "$wif_providers:${k}" => google_iam_workload_identity_pool.default.0.name
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
        plan  = try(v.provider_files.plan, null)
      }
      repository = {
        name           = try(v.repository.name, null)
        type           = try(v.repository.type, null)
        apply_branches = try(v.repository.apply_branches, [])
      }
      service_accounts = {
        apply = try(v.service_accounts.apply, null)
        plan  = try(v.service_accounts.plan, null)
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
    }
    if(
      contains(["github", "gitlab"], try(v.repository.type, "-")) &&
      local.of_outputs_bucket != null
    )
  }
  # raw configuration (shared to the wif files)
  cicd = try(yamldecode(file(local.paths.cicd)), {})
  # iam bindings for service accounts
  cicd_iam = merge(flatten([
    for k, v in local.cicd_workflows : [
      {
        "${k}-apply" = {
          service_account = trimprefix(v.service_accounts.apply, "serviceAccount:")
          principals = (
            v.iam_principals.apply == null
            ? {
              all-repo = format(v.iam_principals.plan, v.wif.id, v.repository.name)
            }
            : {
              for b in v.repository.apply_branches : "branch-${b}" => format(
                v.iam_principals.apply, v.wif.id, v.repository.name, b
              )
            }
          )
        }
      },
      {
        "${k}-plan" = {
          service_account = trimprefix(v.service_accounts.plan, "serviceAccount:")
          principals = {
            all-repo = format(v.iam_principals.plan, v.wif.id, v.repository.name)
          }
        }
      }
    ]
  ])...)
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
  cicd_workflows_files = {
    for k, v in local.cicd_workflows : k => templatefile(
      "assets/workflow-${v.repository.type}.yaml", {
        identity_provider = v.wif.id
        audiences         = v.wif.audiences
        service_accounts = {
          apply = trimprefix(v.service_accounts.apply, "serviceAccount:")
          plan  = trimprefix(v.service_accounts.plan, "serviceAccount:")
        }
        outputs_bucket = local.of_outputs_bucket
        stage_name     = k
        tf_providers_files = {
          apply = v.provider_files.apply
          plan  = v.provider_files.plan
        }
        tf_var_files = v.tfvars_files
      }
    )
  }
}

module "cicd-sa" {
  source   = "../../../modules/iam-service-account"
  for_each = local.cicd_iam
  name     = each.value.service_account
  service_account_reuse = {
    use_data_source = false
  }
  iam_bindings_additive = {
    for k, v in each.value.principals : k => {
      member = v
      role   = "roles/iam.workloadIdentityUser"
    }
  }
}

resource "local_file" "workflows" {
  for_each        = local.of_path == null ? {} : local.cicd_workflows_files
  file_permission = "0644"
  filename        = "${local.of_path}/workflows/${each.key}.yaml"
  content         = each.value
}

resource "google_storage_bucket_object" "workflows" {
  for_each = local.output_files.storage_bucket == null ? {} : local.cicd_workflows_files
  bucket   = local.of_outputs_bucket
  name     = "workflows/${each.key}.yaml"
  content  = each.value
}
