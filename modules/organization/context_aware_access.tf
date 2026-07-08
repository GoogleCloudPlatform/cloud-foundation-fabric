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

# tfdoc:file:description Context-Aware Access resources and factory.

locals {
  _access_levels_factory_path = pathexpand(
    coalesce(var.factories_config.access_levels, "-")
  )
  _access_levels_factory_data_raw = merge([
    for f in try(fileset(local._access_levels_factory_path, "*.yaml"), []) :
    yamldecode(file("${local._access_levels_factory_path}/${f}"))
  ]...)
  _access_levels_factory_data = {
    for k, v in local._access_levels_factory_data_raw : k => {
      combining_function = try(v.combining_function, null)
      conditions = [
        for c in try(v.conditions, []) : merge({
          device_policy          = null
          ip_subnetworks         = []
          members                = []
          negate                 = null
          regions                = []
          required_access_levels = []
          vpc_subnets            = {}
        }, c)
      ]
      description = try(v.description, null)
      title       = try(v.title, null)
    }
  }
  access_levels = merge(
    local._access_levels_factory_data,
    var.access_levels
  )
  ctx_access_levels = merge(local.ctx.access_levels, {
    for k, v in google_access_context_manager_access_level.basic :
    "$access_levels:${k}" => v.id
  })
}

resource "google_access_context_manager_access_level" "basic" {
  for_each    = local.access_levels
  parent      = "accessPolicies/${var.access_policy}"
  name        = "accessPolicies/${var.access_policy}/accessLevels/${each.key}"
  title       = coalesce(each.value.title, each.key)
  description = each.value.description
  basic {
    combining_function = each.value.combining_function
    dynamic "conditions" {
      for_each = toset(each.value.conditions)
      iterator = c
      content {
        ip_subnetworks = c.value.ip_subnetworks
        members = [
          for i in c.value.members : lookup(local.ctx.iam_principals, i, i)
        ]
        negate                 = c.value.negate
        regions                = c.value.regions
        required_access_levels = coalesce(c.value.required_access_levels, [])
        dynamic "device_policy" {
          for_each = c.value.device_policy == null ? [] : [c.value.device_policy]
          iterator = dp
          content {
            allowed_device_management_levels = (
              dp.value.allowed_device_management_levels
            )
            allowed_encryption_statuses = (
              dp.value.allowed_encryption_statuses
            )
            require_admin_approval = dp.value.require_admin_approval
            require_corp_owned     = dp.value.require_corp_owned
            require_screen_lock    = dp.value.require_screen_lock
            dynamic "os_constraints" {
              for_each = toset(
                dp.value.os_constraints == null
                ? []
                : dp.value.os_constraints
              )
              iterator = oc
              content {
                minimum_version            = oc.value.minimum_version
                os_type                    = oc.value.os_type
                require_verified_chrome_os = oc.value.require_verified_chrome_os
              }
            }

          }
        }
        dynamic "vpc_network_sources" {
          for_each = c.value.vpc_subnets
          iterator = vpc
          content {
            vpc_subnetwork {
              network            = vpc.key
              vpc_ip_subnetworks = vpc.value
            }
          }
        }
      }
    }
  }
}

resource "google_access_context_manager_gcp_user_access_binding" "binding" {
  for_each        = var.context_aware_access_bindings
  organization_id = local.organization_id_numeric
  group_key = lookup(
    local.ctx.email_addresses, each.value.group_key, each.value.group_key
  )
  access_levels = [
    for al in each.value.access_levels :
    lookup(local.ctx_access_levels, al, al)
  ]
  dynamic "scoped_access_settings" {
    for_each = each.value.scoped_access_settings
    iterator = s
    content {
      dynamic "active_settings" {
        for_each = (
          s.value.active_settings == null ? [] : [s.value.active_settings]
        )
        iterator = as
        content {
          access_levels = as.value.access_levels == null ? null : [
            for al in as.value.access_levels :
            lookup(local.ctx_access_levels, al, al)
          ]
        }
      }
      dynamic "dry_run_settings" {
        for_each = (
          s.value.dry_run_settings == null ? [] : [s.value.dry_run_settings]
        )
        iterator = ds
        content {
          access_levels = ds.value.access_levels == null ? null : [
            for al in ds.value.access_levels :
            lookup(local.ctx_access_levels, al, al)
          ]
        }
      }
    }
  }
}
