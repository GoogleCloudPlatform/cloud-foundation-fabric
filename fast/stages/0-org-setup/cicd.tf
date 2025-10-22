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
  _cicd_ctx_wif = try({
    "$wif_pools:${local.wif_pool_name}" = google_iam_workload_identity_pool.default.0.name
  }, {})
  _cicd_ctx_sa = {
    for k, v in merge(local.ctx.iam_principals, module.factory.iam_principals) :
    "$iam_principals:${k}" => v
  }
  # normalize workflow configurations
  _cicd_workflows = {
    for k, v in lookup(local.cicd, "workflows", {}) : k => {
      audiences = try(v.workload_identity_provider.audiences, [])
      identity_provider = try(
        local._cicd_ctx_wif[v.workload_identity_provider.id],
        v.workload_identity_provider.id,
        null
      )
      tf_providers_files = {
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
      tf_var_files = try(v.tfvars_files, [])
    }
    if(
      contains(["github", "gitlab"], try(v.repository.type, "-")) &&
      local.of_outputs_bucket != null
    )
  }
  # raw configuration (the wif files are also users of this local)
  cicd = try(yamldecode(file(local.paths.cicd)), {})
  # iam bindings for WIF principals on service accounts
  cicd_iam = merge(flatten([
    for k, v in local.cicd_workflows : [
      # apply service account
      {
        "${k}-apply" = {
          service_account = v.service_accounts.apply
          principals = (
            v.iam_principals.apply == null
            # no branches, single principal for the whole repo
            ? {
              all-repo = format(
                v.iam_principals.plan, v.identity_provider, v.repository.name
              )
            }
            # branches, one principal per branch
            : {
              for b in v.repository.apply_branches : "branch-${b}" => format(
                v.iam_principals.apply, v.identity_provider, v.repository.name, b
              )
            }
          )
        }
      },
      # plan service account
      {
        "${k}-plan" = {
          service_account = v.service_accounts.plan
          principals = {
            all-repo = format(
              v.iam_principals.plan, v.identity_provider, v.repository.name
            )
          }
        }
      }
    ]
  ])...)
  # final workflows configurations with dereferencing and WIF principal templates
  cicd_workflows = {
    for k, v in local._cicd_workflows : k => merge(v, {
      # identity provider principal definitions
      iam_principals = {
        apply = (
          length(v.repository.apply_branches) > 0
          ? local.wif_defs[v.repository.type].principal_branch
          : null
        )
        plan = local.wif_defs[v.repository.type].principal_repo
      }
      # dereference service account and strip IAM prefix
      service_accounts = {
        apply = trimprefix(try(
          local._cicd_ctx_sa[v.service_accounts.apply], v.service_accounts.apply
        ), "serviceAccount:")
        plan = trimprefix(try(
          local._cicd_ctx_sa[v.service_accounts.plan], v.service_accounts.plan
        ), "serviceAccount:")
      }
    })
    # only keep valid workflow configurations
    if(
      v.tf_providers_files.apply != null && v.tf_providers_files.plan != null &&
      v.repository.name != null && v.identity_provider != null &&
      v.service_accounts.apply != null && v.service_accounts.plan != null
    )
  }
  # generate workflows contents from template
  cicd_workflows_files = {
    for k, v in local.cicd_workflows : k => templatefile(
      "assets/workflow-${v.repository.type}.yaml", merge(v, {
        outputs_bucket = local.of_outputs_bucket
        stage_name     = k
      })
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
