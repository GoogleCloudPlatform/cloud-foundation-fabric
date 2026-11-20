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

# tfdoc:file:description Location-level Discovery Engine singletons and shared context.

locals {
  _ctx_p = "$"
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local._ctx_p}${k}:${kk}" => vv
    } if !endswith(k, "_vars")
  }
  default_license_config = (
    try(var.user_store_config.default_license_config, null) == null
    ? null
    : lookup(
      local.ctx.license_configs,
      var.user_store_config.default_license_config,
      var.user_store_config.default_license_config
    )
  )
  deletion_policy = var.deletion_protection ? "PREVENT" : "DELETE"
  egress_agent_gateway = (
    var.egress_agent_gateway == null
    ? null
    : lookup(
      local.ctx.agent_gateways,
      var.egress_agent_gateway,
      var.egress_agent_gateway
    )
  )
  location   = lookup(local.ctx.locations, var.location, var.location)
  prefix     = var.prefix == null ? "" : "${var.prefix}-"
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  workforce_pool_name = (
    try(var.idp_config.workforce_pool_name, null) == null
    ? null
    : lookup(
      local.ctx.workforce_pools,
      var.idp_config.workforce_pool_name,
      var.idp_config.workforce_pool_name
    )
  )
}

resource "google_discovery_engine_acl_config" "default" {
  count    = var.idp_config == null ? 0 : 1
  project  = local.project_id
  location = local.location

  idp_config {
    idp_type = var.idp_config.idp_type

    dynamic "external_idp_config" {
      for_each = var.idp_config.idp_type == "THIRD_PARTY" ? [""] : []

      content {
        workforce_pool_name = local.workforce_pool_name
      }
    }
  }
}

resource "google_discovery_engine_cmek_config" "default" {
  count           = var.encryption_config == null ? 0 : 1
  project         = local.project_id
  location        = local.location
  cmek_config_id  = var.encryption_config.cmek_config_id
  deletion_policy = local.deletion_policy
  kms_key = lookup(
    local.ctx.kms_keys,
    var.encryption_config.kms_key,
    var.encryption_config.kms_key
  )
  set_default = var.encryption_config.set_default

  dynamic "single_region_keys" {
    for_each = var.encryption_config.single_region_keys

    content {
      kms_key = lookup(
        local.ctx.kms_keys,
        single_region_keys.value,
        single_region_keys.value
      )
    }
  }
}

resource "google_discovery_engine_user_store" "default" {
  count                              = var.user_store_config == null ? 0 : 1
  project                            = local.project_id
  location                           = local.location
  user_store_id                      = "default_user_store"
  default_license_config             = local.default_license_config
  enable_expired_license_auto_update = var.user_store_config.enable_expired_license_auto_update
  enable_license_auto_register       = var.user_store_config.enable_license_auto_register
}
