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

# tfdoc:file:description Model Armor floor setting.

locals {
  _model_armor_rai = coalesce(
    try(var.model_armor_floor_setting.filters.rai, null), {}
  )
  # rai_filters is a list, follow the API enum order to keep it stable
  _model_armor_rai_types = [
    "SEXUALLY_EXPLICIT", "HATE_SPEECH", "HARASSMENT", "DANGEROUS"
  ]
  _model_armor_sdp    = try(var.model_armor_floor_setting.filters.sdp, null)
  model_armor_filters = try(var.model_armor_floor_setting.filters, null)
  model_armor_rai_filters = [
    for k in local._model_armor_rai_types : {
      confidence_level = local._model_armor_rai[k]
      filter_type      = k
    } if lookup(local._model_armor_rai, k, null) != null
  ]
  # empty sdp settings are dropped by the API and cause a permanent diff
  model_armor_sdp = (
    local._model_armor_sdp == null
    ? null
    : (
      alltrue([for v in values(local._model_armor_sdp) : v == null])
      ? null
      : local._model_armor_sdp
    )
  )
  model_armor_services = {
    for k in ["ai_platform", "google_mcp_server"] :
    k => var.model_armor_floor_setting.integrated_services[k]
    if try(
      var.model_armor_floor_setting.integrated_services[k], null
    ) != null
  }
}

resource "google_model_armor_floorsetting" "default" {
  count                            = var.model_armor_floor_setting == null ? 0 : 1
  parent                           = var.organization_id
  location                         = "global"
  enable_floor_setting_enforcement = var.model_armor_floor_setting.enforce
  integrated_services = [
    for k in keys(local.model_armor_services) : upper(k)
  ]
  filter_config {
    dynamic "malicious_uri_filter_settings" {
      for_each = (
        local.model_armor_filters.malicious_uris == null ? [] : [""]
      )
      content {
        filter_enforcement = (
          local.model_armor_filters.malicious_uris ? "ENABLED" : "DISABLED"
        )
      }
    }
    dynamic "pi_and_jailbreak_filter_settings" {
      for_each = (
        local.model_armor_filters.pi_and_jailbreak == null ? [] : [""]
      )
      content {
        filter_enforcement = "ENABLED"
        confidence_level = (
          local.model_armor_filters.pi_and_jailbreak.confidence_level
        )
      }
    }
    dynamic "rai_settings" {
      for_each = length(local.model_armor_rai_filters) == 0 ? [] : [""]
      content {
        dynamic "rai_filters" {
          for_each = local.model_armor_rai_filters
          content {
            filter_type      = rai_filters.value.filter_type
            confidence_level = rai_filters.value.confidence_level
          }
        }
      }
    }
    dynamic "sdp_settings" {
      for_each = local.model_armor_sdp == null ? [] : [""]
      content {
        dynamic "basic_config" {
          for_each = local.model_armor_sdp.basic == null ? [] : [""]
          content {
            filter_enforcement = (
              local.model_armor_sdp.basic ? "ENABLED" : "DISABLED"
            )
          }
        }
        dynamic "advanced_config" {
          for_each = (
            local.model_armor_sdp.inspect_template == null ? [] : [""]
          )
          content {
            inspect_template    = local.model_armor_sdp.inspect_template
            deidentify_template = local.model_armor_sdp.deidentify_template
          }
        }
      }
    }
  }
  dynamic "ai_platform_floor_setting" {
    for_each = (
      lookup(local.model_armor_services, "ai_platform", null) == null
      ? [] : [local.model_armor_services.ai_platform]
    )
    iterator = config
    content {
      enable_cloud_logging = config.value.cloud_logging
      inspect_only         = config.value.mode == "inspect_only" ? true : null
      inspect_and_block = (
        config.value.mode == "inspect_and_block" ? true : null
      )
    }
  }
  # always sent, the API rejects updates without it once it has been set
  floor_setting_metadata {
    multi_language_detection {
      enable_multi_language_detection = coalesce(
        var.model_armor_floor_setting.multi_language_detection, false
      )
    }
  }
  dynamic "google_mcp_server_floor_setting" {
    for_each = (
      lookup(local.model_armor_services, "google_mcp_server", null) == null
      ? [] : [local.model_armor_services.google_mcp_server]
    )
    iterator = config
    content {
      enable_cloud_logging = config.value.cloud_logging
      inspect_only         = config.value.mode == "inspect_only" ? true : null
      inspect_and_block = (
        config.value.mode == "inspect_and_block" ? true : null
      )
    }
  }
  lifecycle {
    precondition {
      # the API rejects integrated services on organizations and folders
      condition     = length(local.model_armor_services) == 0
      error_message = "Integrated services are only supported on projects."
    }
  }
  depends_on = [
    # in case floor setting or DLP roles are granted in the same module call
    google_organization_iam_binding.authoritative,
    google_organization_iam_binding.bindings,
    google_organization_iam_member.bindings
  ]
}
