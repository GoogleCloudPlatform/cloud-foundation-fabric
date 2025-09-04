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
  _cicd = try(yamldecode(file(local.paths.cicd)), {})
  _cicd_identity_providers = {
    for k, v in google_iam_workload_identity_pool_provider.default :
    "$wif_providers:${k}" => v.id
  }
  _cicd_output_files = {
    for k, v in google_storage_bucket_object.providers :
    "$output_files:providers/${k}" => v.name
  }
  cicd_project_ids = {
    for k, v in merge(
      var.context.project_ids, module.factory.project_ids
    ) : "$project_ids:${k}" => v
  }
  cicd_workflows = {
    for k, v in lookup(local._cicd, "workflows", {}) : k => {
      outputs_bucket = lookup(
        local.of_buckets,
        v.output_files.storage_bucket,
        v.output_files.storage_bucket
      )
      workflow = templatefile("assets/workflow-${v.template}.yaml", {
        identity_provider = lookup(
          local._cicd_identity_providers,
          v.workload_identity_provider.id,
          v.workload_identity_provider.id
        )
        service_accounts = {
          apply = lookup(
            local.of_service_accounts,
            v.service_accounts.apply,
            v.service_accounts.apply
          )
          plan = lookup(
            local.of_service_accounts,
            v.service_accounts.plan,
            v.service_accounts.plan
          )
        }
        outputs_bucket = lookup(
          local.of_buckets,
          v.output_files.storage_bucket,
          v.output_files.storage_bucket
        )
        stage_name = k
        tf_providers_files = {
          apply = lookup(
            local._cicd_output_files,
            v.output_files.providers.apply,
            v.output_files.providers.apply
          )
          plan = lookup(
            local._cicd_output_files,
            v.output_files.providers.plan,
            v.output_files.providers.plan
          )
        }
        tf_var_files = try(v.output_files.files, [])
      })
    }
  }
  wif_project = try(local._cicd.workload_identity_federation.project, null)
  wif_providers = {
    for k, v in try(local._cicd.workload_identity_federation.providers, {}) :
    k => merge(v, lookup(local.wif_defs, v.issuer, {}))
  }
}

resource "google_iam_workload_identity_pool" "default" {
  count = local.wif_project == null ? 0 : 1
  project = lookup(
    local.cicd_project_ids, local.wif_project, local.wif_project
  )
  workload_identity_pool_id = try(
    local._cicd.workload_identity_federation.pool_name, "iac-0"
  )
}

resource "google_iam_workload_identity_pool_provider" "default" {
  for_each = local.wif_providers
  project = (
    google_iam_workload_identity_pool.default[0].project
  )
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default[0].workload_identity_pool_id
  )
  workload_identity_pool_provider_id = each.key
  attribute_condition = lookup(
    each.value, "attribute_condition", null
  )
  attribute_mapping = lookup(
    each.value, "attribute_mapping", {}
  )
  oidc {
    # Setting an empty list configures allowed_audiences to the url of the provider
    allowed_audiences = try(each.value.custom_settings.audiences, [])
    # If users don't provide an issuer_uri, we set the public one for the platform chosen.
    issuer_uri = (
      try(each.value.custom_settings.issuer_uri, null) != null
      ? each.value.custom_settings.issuer_uri
      : try(each.value.issuer_uri, null)
    )
    # OIDC JWKs in JSON String format. If no value is provided, they key is
    # fetched from the `.well-known` path for the issuer_uri
    jwks_json = try(each.value.custom_settings.jwks_json, null)
  }
}

resource "local_file" "workflows" {
  for_each        = local.of_path == null ? {} : local.cicd_workflows
  file_permission = "0644"
  filename        = "${local.of_path}/workflows/${each.key}.yaml"
  content         = each.value.workflow
}

resource "google_storage_bucket_object" "workflows" {
  for_each = local.cicd_workflows
  bucket   = each.value.outputs_bucket
  name     = "workflows/${each.key}.yaml"
  content  = each.value.workflow
}
