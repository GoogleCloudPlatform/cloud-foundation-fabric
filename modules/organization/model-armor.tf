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
  model_armor_filters = try(var.model_armor_floor_setting.filters, null)
  model_armor_services = {
    for k, v in try(var.model_armor_floor_setting.integrated_services, {}) :
    k => v if v != null
  }
}

resource "google_model_armor_floorsetting" "default" {
  count                            = local.model_armor_filters == null ? 0 : 1
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
      for_each = length(local.model_armor_filters.rai) == 0 ? [] : [""]
      content {
        dynamic "rai_filters" {
          for_each = local.model_armor_filters.rai
          content {
            filter_type      = rai_filters.key
            confidence_level = rai_filters.value
          }
        }
      }
    }
    dynamic "sdp_settings" {
      for_each = local.model_armor_filters.sdp == null ? [] : [""]
      content {
        dynamic "basic_config" {
          for_each = (
            local.model_armor_filters.sdp.basic == null ? [] : [""]
          )
          content {
            filter_enforcement = (
              local.model_armor_filters.sdp.basic ? "ENABLED" : "DISABLED"
            )
          }
        }
        dynamic "advanced_config" {
          for_each = (
            local.model_armor_filters.sdp.inspect_template == null &&
            local.model_armor_filters.sdp.deidentify_template == null
            ? [] : [""]
          )
          content {
            inspect_template = local.model_armor_filters.sdp.inspect_template
            deidentify_template = (
              local.model_armor_filters.sdp.deidentify_template
            )
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
  dynamic "floor_setting_metadata" {
    for_each = (
      var.model_armor_floor_setting.multi_language_detection == null
      ? [] : [""]
    )
    content {
      multi_language_detection {
        enable_multi_language_detection = (
          var.model_armor_floor_setting.multi_language_detection
        )
      }
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
}
