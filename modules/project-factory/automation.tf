/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# tfdoc:file:description Automation projects locals and resources.

locals {
  _outputs = {
    for k, v in local.automation_outputs_buckets :
    "${k}-outputs" => merge(v, {
      bucket_name = "outputs"
      iam         = lookup(v, "iam", {})
    })
  }
  _tf_state = {
    for k, v in local.automation_buckets :
    k => merge(v, {
      project_key = k
      bucket_name = "tf-state"
      iam         = lookup(v, "iam", {})
    })
  }
  automation_bucket_specs = merge(local._tf_state, local._outputs)
  automation_buckets = {
    for k, v in local.projects :
    k => merge(try(v.automation.bucket, {}), {
      automation_project = v.automation.project
      prefix             = coalesce(try(v.automation.prefix, null), "${v.prefix}-${v.name}")
      project_name       = v.name
    }) if try(v.automation.bucket, null) != null
  }
  automation_outputs_buckets = {
    for k, v in local.projects :
    k => merge(try(v.automation.outputs_bucket, {}), {
      automation_project = v.automation.project
      prefix             = coalesce(try(v.automation.prefix, null), v.automation.project)
      project_name       = v.name
      project_key        = k
    }) if try(v.automation.outputs_bucket, null) != null
  }
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
  wif_binding_additive_map = {
    for wif in local.wif_configs_flat :
    "${wif.project_key}/automation/${wif.sa_key}" => {
      "wif-binding" = {
        role = "roles/iam.workloadIdentityUser"
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
      }
    }
  }
  wif_configs_flat = flatten([
    for project_key, project_config in local.projects : [
      for impersonator, impersonated in try(project_config.automation.cicd_config.impersonations, {}) :
      {
        project_key        = project_key
        automation_project = project_config.automation.project
        sa_key             = impersonator
        impersonated_sa    = impersonated
        identity_provider  = project_config.automation.cicd_config.identity_provider
        repository         = project_config.automation.cicd_config.repository
        branch             = try(project_config.automation.cicd_config.branch, null)
        prefix = coalesce(
          try(project_config.automation.prefix, null),
          "${project_config.prefix}-${project_config.name}"
        )
      } if try(project_config.automation.cicd_config, null) != null
    ]
  ])
  impersonated_sa_metadata = {
    for c in local.wif_configs_flat :
    "${c.project_key}/automation/${c.impersonated_sa}" => {
      project_id = c.automation_project
      prefix     = c.prefix
      name       = c.impersonated_sa
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
    for role, members in lookup(each.value, "iam", {}) :
    role => distinct([
      for m in members :
      try(
        module.automation-service-accounts["${each.value.project_key}/automation/${m}"].iam_email,
        var.factories_config.context.iam_principals[m],
        m
      )
    ])
  }
  iam_bindings = {
    for role_key, binding in lookup(each.value, "iam_bindings", {}) :
    role_key => merge(binding, {
      members = [
        for m in binding.members : try(
          # rw (infer local project and automation prefix)
          module.automation-service-accounts["${each.key}/automation/${m}"].iam_email,
          # automation/rw or sa (infer local project)
          module.automation-service-accounts["${each.key}/${m}"].iam_email,
          # project/automation/rw project/sa
          var.factories_config.context.iam_principals[m],
          # fully specified principal
          m,
          # passthrough + error handling using tonumber until Terraform gets fail/raise function
          (
            strcontains(m, ":")
            ? m
            : tonumber("[Error] Invalid member: '${m}' in automation bucket '${each.key}'")
          )
        )
      ]
    })
  }
  iam_bindings_additive = {
    for role_key, binding in lookup(each.value, "iam_bindings_additive", {}) :
    role_key => merge(binding, {
      member = try(
        module.automation-service-accounts["${each.value.project_key}/automation/${binding.member}"].iam_email,
        var.factories_config.context.iam_principals[binding.member],
        binding.member
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
  display_name = lookup(each.value, "display_name",
  "Service account ${each.value.name} for ${each.value.project}.")
  # TODO: also support short form for service accounts in this project
  iam = {
    for role, members in lookup(each.value, "iam", {}) : role => [
      for m in members : lookup(
        var.factories_config.context.iam_principals,
        m,
        m
      )
    ]
  }
  iam_bindings = {
    for role, binding in lookup(each.value, "iam_bindings", {}) :
    role => merge(binding, {
      members = [
        for m in binding.members : lookup(
          var.factories_config.context.iam_principals,
          m,
          m
        )
      ]
    })
  }
  iam_bindings_additive = {
    for role_key, binding in merge(
      lookup(each.value, "iam_bindings_additive", {}),
      lookup(local.wif_binding_additive_map, each.key, {})
    ) :
    role_key => merge(binding, {
      member = lookup(
        var.factories_config.context.iam_principals,
        binding.member,
        binding.member
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

module "automation_sa_impersonation" {
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