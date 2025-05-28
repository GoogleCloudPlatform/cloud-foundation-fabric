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
  dd_services = {
    for k, v in local.data_domains : k => distinct(concat(
      v.project_config.services,
      lookup(local.dd_composer, k, null) == null ? [] : [
        "composer.googleapis.com",
        "storage.googleapis.com"
      ]
    ))
  }
}

module "dd-folders" {
  source   = "../../../modules/folder"
  for_each = local.data_domains
  parent   = var.folder_ids[var.stage_config.name]
  name     = each.value.name
  iam = {
    for k, v in each.value.folder_config.iam : k => [
      for m in v : lookup(
        var.factories_config.context.iam_principals, m, m
      )
    ]
  }
  iam_bindings = {
    for k, v in each.value.folder_config.iam_bindings : k => merge(v, {
      members = [
        for m in v.members : lookup(
          var.factories_config.context.iam_principals, m, m
        )
      ]
      condition = try(v.condition, null) == null ? null : {
        title       = v.condition.title
        description = try(v.condition.description, null)
        expression = templatestring(v.condition.expression, {
          tag_values = local.tag_values
        })
      }
    })
  }
  iam_bindings_additive = {
    for k, v in each.value.folder_config.iam_bindings_additive : k => merge(v, {
      member = lookup(
        var.factories_config.context.iam_principals, v.member, v.member
      )
      condition = try(v.condition, null) == null ? null : {
        title       = v.condition.title
        description = try(v.condition.description, null)
        expression = templatestring(v.condition.expression, {
          tag_values = local.tag_values
        })
      }
    })
  }
  iam_by_principals = {
    for k, v in each.value.folder_config.iam_by_principals :
    lookup(var.factories_config.context.iam_principals, k, k) => v
  }
}

module "dd-dp-folders" {
  source   = "../../../modules/folder"
  for_each = local.data_domains
  parent   = module.dd-folders[each.key].id
  name     = "Data Products"
  iam = try(each.value.deploy_config.composer, null) == null ? {} : {
    "roles/iam.serviceAccountTokenCreator" = [
      module.dd-composer-sa[each.key].iam_email
    ]
  }
}

module "dd-projects" {
  source          = "../../../modules/project"
  for_each        = local.data_domains
  billing_account = var.billing_account.id
  name            = "${each.value.short_name}-shared-0"
  parent          = module.dd-folders[each.key].id
  prefix          = local.prefix
  labels = {
    data_domain = each.key
  }
  services = local.dd_services[each.key]
  service_encryption_key_ids = (
    lookup(local.dd_composer, each.key, null) == null ? {} : {
      "composer.googleapis.com" = compact([
        try(local.dd_composer_keys[each.key], null) == null
        ? null
        : lookup(
          local.kms_keys,
          local.dd_composer_keys[each.key],
          local.dd_composer_keys[each.key]
        )
      ])
    }
  )
}

module "dd-projects-iam" {
  source   = "../../../modules/project"
  for_each = local.data_domains
  name     = module.dd-projects[each.key].project_id
  project_reuse = {
    use_data_source = false
    project_attributes = {
      name             = module.dd-projects[each.key].name
      number           = module.dd-projects[each.key].number
      services_enabled = local.dd_services[each.key]
    }
  }
  iam = {
    for k, v in each.value.project_config.iam : k => [
      for m in v : try(
        var.factories_config.context.iam_principals[m],
        module.dd-automation-sa["${each.key}/${m}"].iam_email,
        module.dd-service-accounts["${each.key}/${m}"].iam_email,
        m
      )
    ]
  }
  iam_bindings = {
    for k, v in each.value.project_config.iam_bindings : k => merge(v, {
      members = [
        for m in v.members : try(
          var.factories_config.context.iam_principals[m],
          module.dd-automation-sa["${each.key}/${m}"].iam_email,
          module.dd-service-accounts["${each.key}/${m}"].iam_email,
          m
        )
      ]
      condition = try(v.condition, null) == null ? null : {
        title       = v.condition.title
        description = try(v.condition.description, null)
        expression = templatestring(v.condition.expression, {
          tag_values = local.tag_values
        })
      }
    })
  }
  iam_bindings_additive = merge(
    {
      for k, v in each.value.project_config.iam_bindings_additive : k => merge(v, {
        member = try(
          var.factories_config.context.iam_principals[v.member],
          module.dd-automation-sa["${each.key}/${v.member}"].iam_email,
          module.dd-service-accounts["${each.key}/${v.member}"].iam_email,
          v.member
        )
        condition = try(v.condition, null) == null ? null : {
          title       = v.condition.title
          description = try(v.condition.description, null)
          expression = templatestring(v.condition.expression, {
            tag_values = local.tag_values
          })
        }
      })
    },
    try(each.value.deploy_config.composer, null) == null ? {} : {
      composer_worker = {
        member = module.dd-composer-sa[each.key].iam_email
        role   = "roles/composer.worker"
      }
    }
  )
  iam_by_principals = {
    for k, v in each.value.project_config.iam_by_principals :
    lookup(var.factories_config.context.iam_principals, k, k) => v
  }
  shared_vpc_service_config = (
    each.value.project_config.shared_vpc_service_config == null
    ? null
    : {
      host_project = lookup(
        var.host_project_ids,
        each.value.project_config.shared_vpc_service_config.host_project,
        each.value.project_config.shared_vpc_service_config.host_project
      )
      network_users = [
        for m in try(each.value.project_config.shared_vpc_service_config.network_users, []) :
        try(
          var.factories_config.context.iam_principals[m],
          module.dd-automation-sa["${each.key}/${m}"].iam_email,
          module.dd-service-accounts["${each.key}/${m}"].iam_email,
          m
        )
      ]
      service_agent_iam = try(
        each.value.project_config.shared_vpc_service_config.service_agent_iam,
        {}
      )
      service_iam_grants = try(
        each.value.project_config.shared_vpc_service_config.service_iam_grants,
        []
      )
    }
  )
}

module "dd-service-accounts" {
  source      = "../../../modules/iam-service-account"
  for_each    = { for v in local.dd_service_accounts : v.key => v }
  project_id  = module.dd-projects[each.value.dd].project_id
  prefix      = local.prefix
  name        = each.value.name
  description = each.value.description
  iam = {
    for k, v in each.value.iam : k => [
      for m in v : lookup(
        var.factories_config.context.iam_principals, m, m
      )
    ]
  }
  iam_bindings = {
    for k, v in each.value.iam_bindings : k => merge(v, {
      members = [
        for m in v.members : lookup(
          var.factories_config.context.iam_principals, m, m
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in each.value.iam_bindings_additive : k => merge(v, {
      member = lookup(
        var.factories_config.context.iam_principals, v.member, v.member
      )
    })
  }
  iam_storage_roles = each.value.iam_storage_roles
}
