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
  assistant = try(
    var.engines_configs.search_engine_config.assistant_config, null
  )
  assistant_armor  = try(local.assistant_policy.model_armor_config, null)
  assistant_gen    = try(local.assistant.generation_config, null)
  assistant_policy = try(local.assistant.customer_policy, null)
  search           = var.engines_configs.search_engine_config
  widget           = try(local.search.widget_config, null)
  widget_access    = try(local.widget.access_settings, null)
  widget_branding  = try(local.widget.ui_branding, null)
  widget_gen       = try(local.widget_ui.generative_answer_config, null)
  widget_homepage  = try(local.widget.homepage_setting, null)
  widget_ui        = try(local.widget.ui_settings, null)
  widget_ui_data_stores = {
    for k, v in coalesce(
      try(local.widget_ui.data_store_ui_configs, null), {}
    ) :
    k => merge(v, {
      name = (
        contains(keys(google_discovery_engine_data_store.default), k)
        ? google_discovery_engine_data_store.default[k].name
        : k
      )
    })
  }
}

resource "google_discovery_engine_chat_engine" "default" {
  count         = var.engines_configs.chat_engine_config == null ? 0 : 1
  engine_id     = var.name
  display_name  = var.name
  collection_id = var.engines_configs.collection_id
  project       = local.project_id
  data_store_ids = [
    for ds in var.engines_configs.data_store_ids
    : coalesce(
      try(google_discovery_engine_data_store.default[ds].data_store_id, null),
      ds
    )
  ]
  industry_vertical = coalesce(
    try(var.engines_configs.industry_vertical, null),
    try(google_discovery_engine_data_store.default[var.engines_configs.data_store_ids[0]].industry_vertical, null),
    "GENERIC"
  )
  location = coalesce(
    try(lookup(
      local.ctx.locations,
      var.engines_configs.location,
      var.engines_configs.location
    ), null),
    try(google_discovery_engine_data_store.default[var.engines_configs.data_store_ids[0]].location, null),
    local.location
  )

  chat_engine_config {
    allow_cross_region = var.engines_configs.chat_engine_config.allow_cross_region
    dialogflow_agent_to_link = try(
      coalesce(
        var.engines_configs.chat_engine_config.agent_config.id,
        google_dialogflow_cx_agent.default[0].id
      ),
      null
    )
  }

  dynamic "common_config" {
    for_each = (
      var.engines_configs.chat_engine_config.company_name == null
      ? [] : [""]
    )

    content {
      company_name = var.engines_configs.chat_engine_config.company_name
    }
  }

  # CMEK and ACL config have to be registered before engines are created
  depends_on = [
    google_discovery_engine_acl_config.default,
    google_discovery_engine_cmek_config.default
  ]
}

resource "google_discovery_engine_search_engine" "default" {
  count         = local.search == null ? 0 : 1
  engine_id     = var.name
  display_name  = var.name
  collection_id = var.engines_configs.collection_id
  project       = local.project_id
  data_store_ids = [
    for ds in var.engines_configs.data_store_ids
    : coalesce(
      try(google_discovery_engine_data_store.default[ds].data_store_id, null),
      ds
    )
  ]
  industry_vertical = coalesce(
    try(var.engines_configs.industry_vertical, null),
    try(google_discovery_engine_data_store.default[var.engines_configs.data_store_ids[0]].industry_vertical, null),
    "GENERIC"
  )
  location = coalesce(
    try(lookup(
      local.ctx.locations,
      var.engines_configs.location,
      var.engines_configs.location
    ), null),
    try(google_discovery_engine_data_store.default[var.engines_configs.data_store_ids[0]].location, null),
    local.location
  )
  app_type          = local.search.app_type
  disable_analytics = local.search.disable_analytics
  features          = local.search.features
  kms_key_name = (
    local.search.kms_key == null
    ? null
    : lookup(
      local.ctx.kms_keys, local.search.kms_key, local.search.kms_key
    )
  )

  dynamic "common_config" {
    for_each = local.search.company_name == null ? [] : [""]

    content {
      company_name = local.search.company_name
    }
  }

  search_engine_config {
    required_subscription_tier = local.search.required_subscription_tier
    search_add_ons             = local.search.search_add_ons
    search_tier                = local.search.search_tier
  }

  # CMEK, ACL, and user stores have to be registered before engines are created
  depends_on = [
    google_discovery_engine_acl_config.default,
    google_discovery_engine_cmek_config.default,
    google_discovery_engine_user_store.default
  ]
}

resource "google_discovery_engine_assistant" "default" {
  count              = local.assistant == null ? 0 : 1
  engine_id          = google_discovery_engine_search_engine.default[0].engine_id
  collection_id      = var.engines_configs.collection_id
  location           = google_discovery_engine_search_engine.default[0].location
  project            = local.project_id
  assistant_id       = local.assistant.assistant_id
  display_name       = coalesce(local.assistant.display_name, var.name)
  description        = local.assistant.description
  web_grounding_type = local.assistant.web_grounding_type

  dynamic "customer_policy" {
    for_each = local.assistant_policy == null ? [] : [""]

    content {
      dynamic "banned_phrases" {
        for_each = local.assistant_policy.banned_phrases

        content {
          ignore_diacritics = banned_phrases.value.ignore_diacritics
          match_type        = banned_phrases.value.match_type
          phrase = coalesce(
            banned_phrases.value.phrase, banned_phrases.key
          )
        }
      }

      dynamic "model_armor_config" {
        for_each = local.assistant_armor == null ? [] : [""]

        content {
          failure_mode = local.assistant_armor.failure_mode
          response_template = lookup(
            local.ctx.model_armor_templates,
            local.assistant_armor.response_template,
            local.assistant_armor.response_template
          )
          user_prompt_template = lookup(
            local.ctx.model_armor_templates,
            local.assistant_armor.user_prompt_template,
            local.assistant_armor.user_prompt_template
          )
        }
      }
    }
  }

  dynamic "generation_config" {
    for_each = local.assistant_gen == null ? [] : [""]

    content {
      default_language = local.assistant_gen.default_language

      dynamic "system_instruction" {
        for_each = (
          local.assistant_gen.system_instruction == null ? [] : [""]
        )

        content {
          additional_system_instruction = (
            local.assistant_gen.system_instruction.additional_system_instruction
          )
        }
      }
    }
  }
}

resource "google_discovery_engine_widget_config" "default" {
  count            = local.widget == null ? 0 : 1
  engine_id        = google_discovery_engine_search_engine.default[0].engine_id
  collection_id    = var.engines_configs.collection_id
  location         = google_discovery_engine_search_engine.default[0].location
  project          = local.project_id
  widget_config_id = local.widget.widget_config_id

  dynamic "access_settings" {
    for_each = local.widget_access == null ? [] : [""]

    content {
      allow_public_access = local.widget_access.allow_public_access
      allowlisted_domains = local.widget_access.allowlisted_domains
      enable_web_app      = local.widget_access.enable_web_app
      language_code       = local.widget_access.language_code
      workforce_identity_pool_provider = (
        local.widget_access.workforce_identity_pool_provider
      )
    }
  }

  dynamic "homepage_setting" {
    for_each = local.widget_homepage == null ? [] : [""]

    content {
      dynamic "shortcuts" {
        for_each = local.widget_homepage.shortcuts

        content {
          destination_uri = shortcuts.value.destination_uri
          title           = shortcuts.value.title

          dynamic "icon" {
            for_each = shortcuts.value.icon_url == null ? [] : [""]

            content {
              url = shortcuts.value.icon_url
            }
          }
        }
      }
    }
  }

  dynamic "ui_branding" {
    for_each = local.widget_branding == null ? [] : [""]

    content {
      dynamic "logo" {
        for_each = local.widget_branding.logo == null ? [] : [""]

        content {
          url = local.widget_branding.logo.url
        }
      }
    }
  }

  dynamic "ui_settings" {
    for_each = local.widget_ui == null ? [] : [""]

    content {
      default_search_request_order_by = (
        local.widget_ui.default_search_request_order_by
      )
      disable_user_events_collection = (
        local.widget_ui.disable_user_events_collection
      )
      enable_autocomplete           = local.widget_ui.enable_autocomplete
      enable_create_agent_button    = local.widget_ui.enable_create_agent_button
      enable_people_search          = local.widget_ui.enable_people_search
      enable_quality_feedback       = local.widget_ui.enable_quality_feedback
      enable_safe_search            = local.widget_ui.enable_safe_search
      enable_search_as_you_type     = local.widget_ui.enable_search_as_you_type
      enable_visual_content_summary = local.widget_ui.enable_visual_content_summary
      interaction_type              = local.widget_ui.interaction_type
      result_description_type       = local.widget_ui.result_description_type

      dynamic "data_store_ui_configs" {
        for_each = local.widget_ui_data_stores

        content {
          name = data_store_ui_configs.value.name

          dynamic "facet_field" {
            for_each = data_store_ui_configs.value.facet_fields

            content {
              display_name = facet_field.value
              field        = facet_field.key
            }
          }

          dynamic "fields_ui_components_map" {
            for_each = data_store_ui_configs.value.fields_ui_components
            iterator = ui_component

            content {
              device_visibility = ui_component.value.device_visibility
              display_template  = ui_component.value.display_template
              field             = ui_component.value.field
              ui_component      = ui_component.key
            }
          }
        }
      }

      dynamic "generative_answer_config" {
        for_each = local.widget_gen == null ? [] : [""]

        content {
          disable_related_questions   = local.widget_gen.disable_related_questions
          ignore_adversarial_query    = local.widget_gen.ignore_adversarial_query
          ignore_low_relevant_content = local.widget_gen.ignore_low_relevant_content
          ignore_non_answer_seeking_query = (
            local.widget_gen.ignore_non_answer_seeking_query
          )
          image_source          = local.widget_gen.image_source
          language_code         = local.widget_gen.language_code
          max_rephrase_steps    = local.widget_gen.max_rephrase_steps
          model_prompt_preamble = local.widget_gen.model_prompt_preamble
          model_version         = local.widget_gen.model_version
          result_count          = local.widget_gen.result_count
        }
      }
    }
  }
}
