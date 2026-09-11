/**
 * Copyright 2026 Google LLC
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
  projects_buckets = flatten([
    for k, v in local.projects_input : [
      for name, opts in lookup(v, "buckets", {}) : {
        key          = "${k}/${name}"
        project_key  = k
        project_name = v.name
        # coalesce as typed var entries return null from lookup
        name = coalesce(
          lookup(opts, "name", null), "${v.name}-${name}"
        )
        create    = lookup(opts, "create", true)
        autoclass = lookup(opts, "autoclass", null)
        cors      = lookup(opts, "cors", null)
        default_event_based_hold = lookup(
          opts, "default_event_based_hold", null
        )
        enable_hierarchical_namespace = lookup(
          opts, "enable_hierarchical_namespace", null
        )
        encryption_key = lookup(opts, "encryption_key", null)
        force_destroy = try(coalesce(
          local.data_defaults.overrides.bucket.force_destroy,
          try(opts.force_destroy, null),
          local.data_defaults.defaults.bucket.force_destroy,
        ), null)
        iam                   = lookup(opts, "iam", {})
        iam_bindings          = lookup(opts, "iam_bindings", {})
        iam_bindings_additive = lookup(opts, "iam_bindings_additive", {})
        iam_by_principals     = lookup(opts, "iam_by_principals", {})
        ip_filter             = lookup(opts, "ip_filter", null)
        labels                = lookup(opts, "labels", {})
        location              = lookup(opts, "location", null)
        managed_folders       = lookup(opts, "managed_folders", {})
        notification_config   = lookup(opts, "notification_config", null)
        prefix = try(coalesce(
          local.data_defaults.overrides.prefix,
          try(v.prefix, null),
          local.data_defaults.defaults.prefix
        ), null)
        public_access_prevention = lookup(
          opts, "public_access_prevention", null
        )
        requester_pays = lookup(opts, "requester_pays", null)
        rpo            = lookup(opts, "rpo", null)
        storage_class = lookup(
          opts, "storage_class", "STANDARD"
        )
        uniform_bucket_level_access = lookup(
          opts, "uniform_bucket_level_access", true
        )
        versioning = lookup(
          opts, "versioning", false
        )
        retention_policy        = lookup(opts, "retention_policy", null)
        soft_delete_retention   = lookup(opts, "soft_delete_retention", null)
        lifecycle_rules         = lookup(opts, "lifecycle_rules", {})
        logging_config          = lookup(opts, "logging_config", null)
        enable_object_retention = lookup(opts, "enable_object_retention", null)
        tag_bindings            = lookup(opts, "tag_bindings", {})
        custom_placement_config = lookup(opts, "custom_placement_config", null)
        website                 = lookup(opts, "website", null)
      }
    ]
  ])
}

module "buckets" {
  source                        = "../gcs"
  for_each                      = { for k in local.projects_buckets : k.key => k }
  project_id                    = module.projects-iam[each.value.project_key].project_id
  prefix                        = each.value.prefix
  name                          = each.value.name
  autoclass                     = each.value.autoclass
  bucket_create                 = each.value.create
  cors                          = each.value.cors
  default_event_based_hold      = each.value.default_event_based_hold
  enable_hierarchical_namespace = each.value.enable_hierarchical_namespace
  encryption_key                = each.value.encryption_key
  force_destroy                 = each.value.force_destroy
  context = merge(local.ctx, {
    tag_vars = {
      projects     = merge(try(local.ctx.tag_vars.projects, {}), local.tag_vars_projects)
      organization = try(local.ctx.tag_vars.organization, {})
    }
    iam_principals = merge(
      local.ctx.iam_principals,
      local.projects_sas_iam_emails,
      local.automation_sas_iam_emails,
      local.projects_service_agents,
      lookup(local.per_project_service_agents, each.value.project_key, {}),
      lookup(local.self_sas_iam_emails, each.value.project_key, {})
    )
    kms_keys        = merge(local.ctx.kms_keys, local.kms_keys, local.kms_autokeys)
    locations       = local.ctx.locations
    project_ids     = local.ctx_project_ids
    storage_buckets = local.ctx.storage_buckets
    tag_keys        = local.ctx_tag_keys
    tag_values      = local.ctx_tag_values
  })
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_by_principals     = each.value.iam_by_principals
  ip_filter             = each.value.ip_filter
  labels                = each.value.labels
  lifecycle_rules       = each.value.lifecycle_rules
  location = coalesce(
    local.data_defaults.overrides.locations.storage,
    lookup(each.value, "location", null),
    local.data_defaults.defaults.locations.storage
  )
  managed_folders             = each.value.managed_folders
  notification_config         = each.value.notification_config
  public_access_prevention    = each.value.public_access_prevention
  requester_pays              = each.value.requester_pays
  rpo                         = each.value.rpo
  storage_class               = each.value.storage_class
  uniform_bucket_level_access = each.value.uniform_bucket_level_access
  versioning                  = each.value.versioning
  retention_policy            = each.value.retention_policy
  soft_delete_retention       = each.value.soft_delete_retention
  logging_config              = each.value.logging_config
  enable_object_retention     = each.value.enable_object_retention
  tag_bindings                = each.value.tag_bindings
  custom_placement_config     = each.value.custom_placement_config
  website                     = each.value.website
}
