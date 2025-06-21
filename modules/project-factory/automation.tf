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

# tfdoc:file:description Automation projects locals and resources.

locals {
  _existing_outputs_buckets = {
    for k, v in local.projects :
    k => v.automation.outputs_bucket.name
    if try(v.automation.outputs_bucket.name, null) != null
  }
  _outputs_buckets_to_create = {
    for k, v in local.projects :
    "${k}-outputs" => merge(
      {
        bucket_name : "outputs"
      },
      try(v.automation.outputs_bucket.create_new, {}),
      {
        automation_project : v.automation.project,
        project_key : k,
        prefix : coalesce(
          try(v.automation.outputs_bucket.create_new.prefix, null),
          try(v.automation.prefix, null),
          v.automation.project
        )
      }
    ) if try(v.automation.outputs_bucket.create_new, null) != null
  }
  _tf_state_buckets_to_create = {
    for k, v in local.projects :
    k => merge(
      {
        bucket_name : "tf-state"
      },
      try(v.automation.bucket, {}),
      {
        automation_project : v.automation.project,
        prefix : coalesce(
          try(v.automation.bucket.prefix, null),
          try(v.automation.prefix, null),
          "${v.prefix}-${v.name}"
        ),
        project_key : k
      }
    ) if try(v.automation.bucket, null) != null
  }
  automation_bucket_specs = merge(
    local._tf_state_buckets_to_create,
    local._outputs_buckets_to_create
  )
  automation_sa = flatten([
    for k, v in local.projects :
    [
      for ks, kv in try(v.automation.service_accounts, {}) :
      merge(kv, {
        automation_project = v.automation.project
        name               = ks
        prefix             = coalesce(try(v.automation.prefix, null), "${v.prefix}-${v.name}")
        project            = k
        project_name       = v.name
      })
    ]
  ])
  impersonated_sa_metadata = {
    for c in local.wif_configs_flat :
    "${c.project_key}/automation/${c.impersonated_sa}" => {
      name       = c.impersonated_sa
      prefix     = c.prefix
      project_id = c.automation_project
    }
  }
  impersonators_by_impersonated = {
    for target_sa_key in distinct(
      [
        for c in local.wif_configs_flat : "${c.project_key}/automation/${c.impersonated_sa}"
      ]
    ) :
    target_sa_key => [
      for config in local.wif_configs_flat :
      "${config.project_key}/automation/${config.sa_key}"
      if "${config.project_key}/automation/${config.impersonated_sa}" == target_sa_key
    ]
  }
  wif_binding_additive_map = {
    for wif in local.wif_configs_flat :
    "${wif.project_key}/automation/${wif.sa_key}" => {
      "wif-binding" = {
        member = (
          wif.branch == null
          ? format(var.factories_config.context.federated_identity_providers[wif.identity_provider].principal_repo,
            var.factories_config.context.federated_identity_pool,
          wif.repository)
          : format(var.factories_config.context.federated_identity_providers[wif.identity_provider].principal_branch,
            var.factories_config.context.federated_identity_pool,
            wif.repository,
          wif.branch)
        )
        role = "roles/iam.workloadIdentityUser"
      }
    }
  }
  wif_configs_flat = flatten([
    for project_key, project_config in local.projects : [
      for impersonator, impersonated in try(project_config.automation.cicd_config.impersonations, {}) :
      {
        automation_project = project_config.automation.project
        branch             = try(project_config.automation.cicd_config.branch, null)
        identity_provider  = project_config.automation.cicd_config.identity_provider
        impersonated_sa    = impersonated
        prefix = coalesce(
          try(project_config.automation.prefix, null),
          "${project_config.prefix}-${project_config.name}"
        )
        project_key = project_key
        repository  = project_config.automation.cicd_config.repository
        sa_key      = impersonator
      } if try(project_config.automation.cicd_config, null) != null
    ]
  ])
}

module "automation-bucket" {
  source = "../gcs"
  # we cannot use interpolation here as we would get a cycle
  # from the IAM dependency in the outputs of the main project
  for_each       = local.automation_bucket_specs
  project_id     = each.value.automation_project
  prefix         = each.value.prefix
  name           = each.value.bucket_name
  encryption_key = lookup(each.value, "encryption_key", null)
  iam = {
    for k, v in lookup(each.value, "iam", {}) :
    k => distinct([
      for vv in v :
      try(
        module.automation-service-accounts["${each.value.project_key}/automation/${vv}"].iam_email,
        var.factories_config.context.iam_principals[vv],
        vv
      )
    ])
  }
  iam_bindings = {
    for k, v in lookup(each.value, "iam_bindings", {}) :
    k => merge(v, {
      members = [
        for vv in v.members : try(
          # rw (infer local project and automation prefix)
          module.automation-service-accounts["${each.key}/automation/${vv}"].iam_email,
          # automation/rw or sa (infer local project)
          module.automation-service-accounts["${each.key}/${vv}"].iam_email,
          # project/automation/rw project/sa
          var.factories_config.context.iam_principals[vv],
          # fully specified principal
          vv,
          # passthrough + error handling using tonumber until Terraform gets fail/raise function
          (
            strcontains(vv, ":")
            ? vv
            : tonumber("[Error] Invalid member: '${vv}' in automation bucket '${each.key}'")
          )
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in lookup(each.value, "iam_bindings_additive", {}) :
    k => merge(v, {
      member = try(
        module.automation-service-accounts["${each.value.project_key}/automation/${v.member}"].iam_email,
        var.factories_config.context.iam_principals[v.member],
        v.member
      )
    })
  }
  labels = lookup(each.value, "labels", {})
  location = coalesce(
    var.data_overrides.storage_location,
    lookup(each.value, "location", null),
    var.data_defaults.storage_location
  )
  storage_class = lookup(
    each.value, "storage_class", "STANDARD"
  )
  uniform_bucket_level_access = lookup(
    each.value, "uniform_bucket_level_access", true
  )
  versioning = lookup(
    each.value, "versioning", false
  )
}

module "automation-service-accounts" {
  source = "../iam-service-account"
  # we cannot use interpolation here as we would get a cycle
  # from the IAM dependency in the outputs of the main project
  for_each = {
    for k in local.automation_sa :
    "${k.project}/automation/${k.name}"
    => k
  }
  project_id  = each.value.automation_project
  prefix      = each.value.prefix
  name        = each.value.name
  description = lookup(each.value, "description", null)
  display_name = lookup(
    each.value,
    "display_name",
    "Service account ${each.value.name} for ${each.value.project}."
  )
  # TODO: also support short form for service accounts in this project
  iam = {
    for k, v in lookup(each.value, "iam", {}) :
    k => [
      for vv in v : lookup(
        var.factories_config.context.iam_principals,
        vv,
        vv
      )
    ]
  }
  iam_bindings = {
    for k, v in lookup(each.value, "iam_bindings", {}) :
    k => merge(v, {
      members = [
        for vv in v.members : lookup(
          var.factories_config.context.iam_principals,
          vv,
          vv
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in merge(
      lookup(each.value, "iam_bindings_additive", {}),
      lookup(local.wif_binding_additive_map, each.key, {})
    ) :
    k => merge(v, {
      member = lookup(
        var.factories_config.context.iam_principals,
        v.member,
        v.member
      )
    })
  }
  iam_billing_roles      = lookup(each.value, "iam_billing_roles", {})
  iam_folder_roles       = lookup(each.value, "iam_folder_roles", {})
  iam_organization_roles = lookup(each.value, "iam_organization_roles", {})
  iam_project_roles      = lookup(each.value, "iam_project_roles", {})
  iam_sa_roles           = lookup(each.value, "iam_sa_roles", {})
  # we don't interpolate buckets here as we can't use a dynamic key
  iam_storage_roles = lookup(each.value, "iam_storage_roles", {})
}

module "automation-sa-impersonation" {
  source                 = "../iam-service-account"
  for_each               = local.impersonators_by_impersonated
  service_account_create = false
  project_id             = local.impersonated_sa_metadata[each.key].project_id
  prefix                 = local.impersonated_sa_metadata[each.key].prefix
  name                   = local.impersonated_sa_metadata[each.key].name
  iam_bindings_additive = {
    for i, impersonator_key in each.value :
    "token-creator-${i}" => {
      role   = "roles/iam.serviceAccountTokenCreator"
      member = module.automation-service-accounts[impersonator_key].iam_email
    }
  }

  depends_on = [
    module.automation-service-accounts
  ]
}

data "google_storage_bucket" "outputs_existing" {
  for_each = local._existing_outputs_buckets
  name     = each.value
}
