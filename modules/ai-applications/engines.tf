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

  # CMEK has to be registered before engines are created
  depends_on = [google_discovery_engine_cmek_config.default]
}

resource "google_discovery_engine_search_engine" "default" {
  count         = var.engines_configs.search_engine_config == null ? 0 : 1
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
  app_type          = var.engines_configs.search_engine_config.app_type
  disable_analytics = var.engines_configs.search_engine_config.disable_analytics
  features          = var.engines_configs.search_engine_config.features
  kms_key_name = (
    var.engines_configs.search_engine_config.kms_key == null
    ? null
    : lookup(
      local.ctx.kms_keys,
      var.engines_configs.search_engine_config.kms_key,
      var.engines_configs.search_engine_config.kms_key
    )
  )

  dynamic "common_config" {
    for_each = (
      var.engines_configs.search_engine_config.company_name == null
      ? [] : [""]
    )

    content {
      company_name = var.engines_configs.search_engine_config.company_name
    }
  }

  search_engine_config {
    required_subscription_tier = (
      var.engines_configs.search_engine_config.required_subscription_tier
    )
    search_add_ons = var.engines_configs.search_engine_config.search_add_ons
    search_tier    = var.engines_configs.search_engine_config.search_tier
  }

  # CMEK has to be registered before engines are created
  depends_on = [google_discovery_engine_cmek_config.default]
}

resource "google_discovery_engine_assistant" "default" {
  count         = try(var.engines_configs.search_engine_config.assistant_config, null) == null ? 0 : 1
  engine_id     = google_discovery_engine_search_engine.default[0].engine_id
  collection_id = var.engines_configs.collection_id
  location      = google_discovery_engine_search_engine.default[0].location
  project       = local.project_id
  assistant_id = coalesce(
    var.engines_configs.search_engine_config.assistant_config.assistant_id,
    "default_assistant"
  )
  display_name = coalesce(
    var.engines_configs.search_engine_config.assistant_config.display_name,
    var.name
  )
  description = (
    var.engines_configs.search_engine_config.assistant_config.description
  )
  web_grounding_type = (
    var.engines_configs.search_engine_config.assistant_config.web_grounding_type
  )

  dynamic "customer_policy" {
    for_each = (
      var.engines_configs.search_engine_config.assistant_config.customer_policy == null
      ? [] : [""]
    )

    content {
      dynamic "banned_phrases" {
        for_each = (
          var.engines_configs.search_engine_config.assistant_config.customer_policy.banned_phrases
        )

        content {
          ignore_diacritics = banned_phrases.value.ignore_diacritics
          match_type        = banned_phrases.value.match_type
          phrase            = banned_phrases.value.phrase
        }
      }

      dynamic "model_armor_config" {
        for_each = (
          var.engines_configs.search_engine_config.assistant_config.customer_policy.model_armor_config == null
          ? [] : [""]
        )

        content {
          failure_mode = (
            var.engines_configs.search_engine_config.assistant_config.customer_policy.model_armor_config.failure_mode
          )
          response_template = (
            var.engines_configs.search_engine_config.assistant_config.customer_policy.model_armor_config.response_template
          )
          user_prompt_template = (
            var.engines_configs.search_engine_config.assistant_config.customer_policy.model_armor_config.user_prompt_template
          )
        }
      }
    }
  }

  dynamic "generation_config" {
    for_each = (
      var.engines_configs.search_engine_config.assistant_config.generation_config == null
      ? [] : [""]
    )

    content {
      default_language = (
        var.engines_configs.search_engine_config.assistant_config.generation_config.default_language
      )

      dynamic "system_instruction" {
        for_each = (
          try(var.engines_configs.search_engine_config.assistant_config.generation_config.system_instruction, null) == null
          ? [] : [""]
        )

        content {
          additional_system_instruction = (
            var.engines_configs.search_engine_config.assistant_config.generation_config.system_instruction.additional_system_instruction
          )
        }
      }
    }
  }
}

resource "google_discovery_engine_widget_config" "default" {
  count         = try(var.engines_configs.search_engine_config.widget_config, null) == null ? 0 : 1
  engine_id     = google_discovery_engine_search_engine.default[0].engine_id
  collection_id = var.engines_configs.collection_id
  location      = google_discovery_engine_search_engine.default[0].location
  project       = local.project_id
  widget_config_id = coalesce(
    var.engines_configs.search_engine_config.widget_config.widget_config_id,
    "default_search_widget_config"
  )

  dynamic "access_settings" {
    for_each = (
      var.engines_configs.search_engine_config.widget_config.access_settings == null
      ? [] : [""]
    )

    content {
      allow_public_access = var.engines_configs.search_engine_config.widget_config.access_settings.allow_public_access
      allowlisted_domains = var.engines_configs.search_engine_config.widget_config.access_settings.allowlisted_domains
      enable_web_app      = var.engines_configs.search_engine_config.widget_config.access_settings.enable_web_app
      language_code       = var.engines_configs.search_engine_config.widget_config.access_settings.language_code
      workforce_identity_pool_provider = (
        var.engines_configs.search_engine_config.widget_config.access_settings.workforce_identity_pool_provider
      )
    }
  }

  dynamic "homepage_setting" {
    for_each = (
      var.engines_configs.search_engine_config.widget_config.homepage_setting == null
      ? [] : [""]
    )

    content {
      dynamic "shortcuts" {
        for_each = (
          var.engines_configs.search_engine_config.widget_config.homepage_setting.shortcuts
        )

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
    for_each = (
      var.engines_configs.search_engine_config.widget_config.ui_branding == null
      ? [] : [""]
    )

    content {
      dynamic "logo" {
        for_each = (
          try(var.engines_configs.search_engine_config.widget_config.ui_branding.logo, null) == null
          ? [] : [""]
        )

        content {
          url = var.engines_configs.search_engine_config.widget_config.ui_branding.logo.url
        }
      }
    }
  }

  dynamic "ui_settings" {
    for_each = (
      var.engines_configs.search_engine_config.widget_config.ui_settings == null
      ? [] : [""]
    )

    content {
      default_search_request_order_by = var.engines_configs.search_engine_config.widget_config.ui_settings.default_search_request_order_by
      disable_user_events_collection  = var.engines_configs.search_engine_config.widget_config.ui_settings.disable_user_events_collection
      enable_autocomplete             = var.engines_configs.search_engine_config.widget_config.ui_settings.enable_autocomplete
      enable_create_agent_button      = var.engines_configs.search_engine_config.widget_config.ui_settings.enable_create_agent_button
      enable_people_search            = var.engines_configs.search_engine_config.widget_config.ui_settings.enable_people_search
      enable_quality_feedback         = var.engines_configs.search_engine_config.widget_config.ui_settings.enable_quality_feedback
      enable_safe_search              = var.engines_configs.search_engine_config.widget_config.ui_settings.enable_safe_search
      enable_search_as_you_type       = var.engines_configs.search_engine_config.widget_config.ui_settings.enable_search_as_you_type
      enable_visual_content_summary   = var.engines_configs.search_engine_config.widget_config.ui_settings.enable_visual_content_summary
      interaction_type                = var.engines_configs.search_engine_config.widget_config.ui_settings.interaction_type
      result_description_type         = var.engines_configs.search_engine_config.widget_config.ui_settings.result_description_type

      dynamic "data_store_ui_configs" {
        for_each = (
          var.engines_configs.search_engine_config.widget_config.ui_settings.data_store_ui_configs
        )

        content {
          name = data_store_ui_configs.value.name

          dynamic "facet_field" {
            for_each = data_store_ui_configs.value.facet_field

            content {
              display_name = facet_field.value.display_name
              field        = facet_field.value.field
            }
          }

          dynamic "fields_ui_components_map" {
            for_each = data_store_ui_configs.value.fields_ui_components_map

            content {
              device_visibility = fields_ui_components_map.value.device_visibility
              display_template  = fields_ui_components_map.value.display_template
              field             = fields_ui_components_map.value.field
              ui_component      = fields_ui_components_map.value.ui_component
            }
          }
        }
      }

      dynamic "generative_answer_config" {
        for_each = (
          try(var.engines_configs.search_engine_config.widget_config.ui_settings.generative_answer_config, null) == null
          ? [] : [""]
        )

        content {
          disable_related_questions       = var.engines_configs.search_engine_config.widget_config.ui_settings.generative_answer_config.disable_related_questions
          ignore_adversarial_query        = var.engines_configs.search_engine_config.widget_config.ui_settings.generative_answer_config.ignore_adversarial_query
          ignore_low_relevant_content     = var.engines_configs.search_engine_config.widget_config.ui_settings.generative_answer_config.ignore_low_relevant_content
          ignore_non_answer_seeking_query = var.engines_configs.search_engine_config.widget_config.ui_settings.generative_answer_config.ignore_non_answer_seeking_query
          image_source                    = var.engines_configs.search_engine_config.widget_config.ui_settings.generative_answer_config.image_source
          language_code                   = var.engines_configs.search_engine_config.widget_config.ui_settings.generative_answer_config.language_code
          max_rephrase_steps              = var.engines_configs.search_engine_config.widget_config.ui_settings.generative_answer_config.max_rephrase_steps
          model_prompt_preamble           = var.engines_configs.search_engine_config.widget_config.ui_settings.generative_answer_config.model_prompt_preamble
          model_version                   = var.engines_configs.search_engine_config.widget_config.ui_settings.generative_answer_config.model_version
          result_count                    = var.engines_configs.search_engine_config.widget_config.ui_settings.generative_answer_config.result_count
        }
      }
    }
  }
}
