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

variable "apps" {
  description = "Gemini Enterprise applications, keyed by logical app ID. Omit 'engine' to adopt an existing Console-created app while managing its assistant, widget, gateway binding, and IAM."
  type = map(object({
    assistant = optional(object({
      assistant_id = optional(string, "default_assistant")
      banned_phrases = optional(map(object({
        ignore_diacritics = optional(bool)
        match_type        = optional(string)
        phrase            = optional(string)
      })), {})
      default_web_grounding_toggle_off = optional(bool)
      description                      = optional(string)
      display_name                     = optional(string, "Default Assistant")
      generation_config = optional(object({
        default_language   = optional(string)
        system_instruction = optional(string)
      }))
      model_armor_config = optional(object({
        failure_mode         = optional(string, "FAIL_CLOSED")
        response_template    = optional(string, "")
        user_prompt_template = optional(string, "")
      }))
      web_grounding_type = optional(string)
    }))
    collection_id        = optional(string, "default_collection")
    egress_agent_gateway = optional(string)
    engine = optional(object({
      display_name      = string
      company_name      = optional(string)
      data_store_ids    = optional(list(string), [])
      disable_analytics = optional(bool)
      features          = optional(map(string))
      industry_vertical = optional(string, "GENERIC")
      kms_key           = optional(string)
      knowledge_graph = optional(object({
        cloud_knowledge_graph_types    = optional(list(string), [])
        enable_cloud_knowledge_graph   = optional(bool, false)
        enable_private_knowledge_graph = optional(bool, false)
        feature_config = optional(object({
          disable_private_kg_auto_complete       = optional(bool)
          disable_private_kg_enrichment          = optional(bool)
          disable_private_kg_query_ui_chips      = optional(bool)
          disable_private_kg_query_understanding = optional(bool)
        }))
      }))
      model_configs              = optional(map(string))
      procurement_contact_emails = optional(list(string))
      required_subscription_tier = optional(string)
      search_add_ons             = optional(list(string), ["SEARCH_ADD_ON_LLM"])
      search_tier                = optional(string, "SEARCH_TIER_ENTERPRISE")
    }))
    engine_id = optional(string)
    iam       = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      members = list(string)
      role    = string
    })), {})
    iam_bindings_additive = optional(map(object({
      member = string
      role   = string
    })), {})
    iam_by_principals = optional(map(list(string)), {})
    widget_config = optional(object({
      access_settings = optional(object({
        allow_public_access              = optional(bool)
        allowlisted_domains              = optional(list(string))
        enable_web_app                   = optional(bool)
        language_code                    = optional(string)
        workforce_identity_pool_provider = optional(string)
      }))
      homepage_setting = optional(object({
        shortcuts = optional(map(object({
          destination_uri = optional(string)
          icon_url        = optional(string)
          title           = optional(string)
        })), {})
      }))
      ui_branding = optional(object({
        logo = optional(object({
          url = optional(string)
        }))
      }))
      ui_settings = optional(object({
        data_store_ui_configs = optional(map(object({
          facet_fields = optional(map(string), {})
          fields_ui_components = optional(map(object({
            field             = string
            device_visibility = optional(list(string))
            display_template  = optional(string)
          })), {})
        })), {})
        default_search_request_order_by = optional(string)
        disable_user_events_collection  = optional(bool)
        enable_autocomplete             = optional(bool)
        enable_create_agent_button      = optional(bool)
        enable_people_search            = optional(bool)
        enable_quality_feedback         = optional(bool)
        enable_safe_search              = optional(bool)
        enable_search_as_you_type       = optional(bool)
        enable_visual_content_summary   = optional(bool)
        generative_answer_config = optional(object({
          disable_related_questions       = optional(bool)
          ignore_adversarial_query        = optional(bool)
          ignore_low_relevant_content     = optional(bool)
          ignore_non_answer_seeking_query = optional(bool)
          image_source                    = optional(string)
          language_code                   = optional(string)
          max_rephrase_steps              = optional(number)
          model_prompt_preamble           = optional(string)
          model_version                   = optional(string)
          result_count                    = optional(number)
        }))
        interaction_type        = optional(string)
        result_description_type = optional(string)
        search_addon_spec = optional(object({
          generative_answer_add_on_disabled   = optional(bool)
          kpi_personalization_add_on_disabled = optional(bool)
          semantic_add_on_disabled            = optional(bool)
        }))
        source_admin_display_name_enabled = optional(bool)
      }))
      widget_config_id = optional(string, "default_search_widget_config")
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for a in var.apps :
      try(a.engine.industry_vertical, null) == null
      ? true
      : contains(["GENERIC", "HEALTHCARE_FHIR", "MEDIA"], a.engine.industry_vertical)
    ])
    error_message = "apps[*].engine.industry_vertical must be 'GENERIC', 'HEALTHCARE_FHIR', or 'MEDIA'."
  }

  validation {
    condition = alltrue([
      for a in var.apps :
      try(a.engine.required_subscription_tier, null) == null
      ? true
      : contains([
        "SUBSCRIPTION_TIER_AGENTSPACE_BUSINESS",
        "SUBSCRIPTION_TIER_AGENTSPACE_STARTER",
        "SUBSCRIPTION_TIER_EDU",
        "SUBSCRIPTION_TIER_EDU_EMERGING",
        "SUBSCRIPTION_TIER_EDU_PRO",
        "SUBSCRIPTION_TIER_EDU_PRO_EMERGING",
        "SUBSCRIPTION_TIER_ENTERPRISE",
        "SUBSCRIPTION_TIER_ENTERPRISE_EMERGING",
        "SUBSCRIPTION_TIER_FRONTLINE_STARTER",
        "SUBSCRIPTION_TIER_FRONTLINE_WORKER",
        "SUBSCRIPTION_TIER_SEARCH",
        "SUBSCRIPTION_TIER_SEARCH_AND_ASSISTANT"
      ], a.engine.required_subscription_tier)
    ])
    error_message = "Invalid apps[*].engine.required_subscription_tier value."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.apps : [
        for ao in coalesce(try(a.engine.search_add_ons, null), []) :
        contains(["SEARCH_ADD_ON_LLM", "SEARCH_ADD_ON_UNSPECIFIED"], ao)
      ]
    ]))
    error_message = "apps[*].engine.search_add_ons values must be 'SEARCH_ADD_ON_LLM' or 'SEARCH_ADD_ON_UNSPECIFIED'."
  }

  validation {
    condition = alltrue([
      for a in var.apps :
      try(a.engine.search_tier, null) == null
      ? true
      : contains(["SEARCH_TIER_ENTERPRISE", "SEARCH_TIER_STANDARD"], a.engine.search_tier)
    ])
    error_message = "apps[*].engine.search_tier must be 'SEARCH_TIER_ENTERPRISE' or 'SEARCH_TIER_STANDARD'."
  }

  validation {
    condition = alltrue([
      for a in var.apps :
      try(a.assistant.web_grounding_type, null) == null
      ? true
      : contains([
        "WEB_GROUNDING_TYPE_DISABLED",
        "WEB_GROUNDING_TYPE_ENTERPRISE_WEB_SEARCH",
        "WEB_GROUNDING_TYPE_GOOGLE_SEARCH"
      ], a.assistant.web_grounding_type)
    ])
    error_message = "apps[*].assistant.web_grounding_type must be 'WEB_GROUNDING_TYPE_DISABLED', 'WEB_GROUNDING_TYPE_ENTERPRISE_WEB_SEARCH', or 'WEB_GROUNDING_TYPE_GOOGLE_SEARCH'."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.apps : [
        for bp in values(coalesce(try(a.assistant.banned_phrases, null), {})) :
        bp.match_type == null
        ? true
        : contains(
          ["SIMPLE_STRING_MATCH", "WORD_BOUNDARY_STRING_MATCH"],
          bp.match_type
        )
      ]
    ]))
    error_message = "apps[*].assistant.banned_phrases[*].match_type must be 'SIMPLE_STRING_MATCH' or 'WORD_BOUNDARY_STRING_MATCH'."
  }

  validation {
    condition = alltrue([
      for a in var.apps :
      try(a.assistant.model_armor_config.failure_mode, null) == null
      ? true
      : contains(["FAIL_CLOSED", "FAIL_OPEN"], a.assistant.model_armor_config.failure_mode)
    ])
    error_message = "apps[*].assistant.model_armor_config.failure_mode must be 'FAIL_CLOSED' or 'FAIL_OPEN'."
  }

  validation {
    condition = alltrue([
      for a in var.apps :
      try(a.widget_config.ui_settings.interaction_type, null) == null
      ? true
      : contains(
        ["SEARCH_ONLY", "SEARCH_WITH_ANSWER", "SEARCH_WITH_FOLLOW_UPS"],
        a.widget_config.ui_settings.interaction_type
      )
    ])
    error_message = "apps[*].widget_config.ui_settings.interaction_type must be 'SEARCH_ONLY', 'SEARCH_WITH_ANSWER', or 'SEARCH_WITH_FOLLOW_UPS'."
  }

  validation {
    condition = alltrue([
      for a in var.apps :
      try(a.widget_config.ui_settings.result_description_type, null) == null
      ? true
      : contains(
        ["EXTRACTIVE_ANSWER", "SNIPPET"],
        a.widget_config.ui_settings.result_description_type
      )
    ])
    error_message = "apps[*].widget_config.ui_settings.result_description_type must be 'EXTRACTIVE_ANSWER' or 'SNIPPET'."
  }

  validation {
    condition = alltrue([
      for a in var.apps :
      try(a.widget_config.ui_settings.generative_answer_config.image_source, null) == null
      ? true
      : contains(
        [
          "ALL_AVAILABLE_SOURCES",
          "CORPUS_IMAGE_ONLY",
          "FIGURE_GENERATION_ONLY"
        ],
        a.widget_config.ui_settings.generative_answer_config.image_source
      )
    ])
    error_message = "apps[*].widget_config.ui_settings.generative_answer_config.image_source must be 'ALL_AVAILABLE_SOURCES', 'CORPUS_IMAGE_ONLY', or 'FIGURE_GENERATION_ONLY'."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.apps : [
        for ds_v in values(coalesce(
          try(a.widget_config.ui_settings.data_store_ui_configs, null), {}
          )) : [
          for comp_k in keys(ds_v.fields_ui_components) :
          contains(
            ["custom1", "custom2", "custom3", "thumbnail", "title", "url"],
            comp_k
          )
        ]
      ]
    ]))
    error_message = "Keys in fields_ui_components must be one of 'custom1', 'custom2', 'custom3', 'thumbnail', 'title', or 'url'."
  }

  validation {
    condition = alltrue(flatten([
      for a in var.apps : [
        for ds_v in values(coalesce(
          try(a.widget_config.ui_settings.data_store_ui_configs, null), {}
          )) : [
          for comp_v in values(ds_v.fields_ui_components) : [
            for dev in coalesce(comp_v.device_visibility, []) :
            contains(["DESKTOP", "MOBILE"], dev)
          ]
        ]
      ]
    ]))
    error_message = "device_visibility values in fields_ui_components must be 'DESKTOP' or 'MOBILE'."
  }
}
