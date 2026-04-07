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

variable "data_stores_configs" {
  description = "The ai-applications datastore configurations."
  type = map(object({
    advanced_site_search_config = optional(object({
      disable_initial_index     = optional(bool)
      disable_automatic_refresh = optional(bool)
    }))
    content_config              = optional(string, "NO_CONTENT")
    create_advanced_site_search = optional(bool)
    display_name                = optional(string)
    document_processing_config = optional(object({
      chunking_config = optional(object({
        layout_based_chunking_config = optional(object({
          chunk_size                = optional(number)
          include_ancestor_headings = optional(bool)
        }))
      }))
      default_parsing_config = optional(object({
        digital_parsing_config = optional(bool)
        layout_parsing_config  = optional(bool)
        ocr_parsing_config = optional(object({
          use_native_text = optional(bool)
        }))
      }))
      # Accepted keys: docx, html, pdf
      parsing_config_overrides = optional(map(object({
        digital_parsing_config = optional(bool)
        layout_parsing_config  = optional(bool)
        ocr_parsing_config = optional(object({
          use_native_text = optional(bool)
        }))
      })))
    }))
    industry_vertical            = optional(string, "GENERIC")
    json_schema                  = optional(string)
    location                     = optional(string)
    skip_default_schema_creation = optional(bool)
    solution_types               = optional(list(string))
    sites_search_config = optional(object({
      sitemap_uri = optional(string)
      target_sites = map(object({
        provided_uri_pattern = string
        exact_match          = optional(bool, false)
        type                 = optional(string, "INCLUDE")
      }))
    }))
  }))
  nullable = false
  default  = {}
  validation {
    condition = try(contains(
      ["CONTENT_REQUIRED", "NO_CONTENT", "PUBLIC_WEBSITE"],
      var.data_stores_configs.content_config
    ), true)
    error_message = "data_store_configs.content_config must be one or more of [CONTENT_REQUIRED, NO_CONTENT, PUBLIC_WEBSITE]."
  }
  validation {
    condition = try(contains(
      ["GENERIC", "HEALTHCARE_FHIR", "MEDIA"],
      var.data_stores_configs.industry_vertical
    ), true)
    error_message = "data_store_configs.industry_vertical must be one or more of [GENERIC, HEALTHCARE_FHIR, MEDIA]."
  }
  validation {
    condition = alltrue([
      for st in try(var.data_stores_configs.solution_types, [])
      : contains([
        "SOLUTION_TYPE_CHAT",
        "SOLUTION_TYPE_GENERATIVE_CHAT",
        "SOLUTION_TYPE_RECOMMENDATION",
        "SOLUTION_TYPE_SEARCH"
      ], st)
    ])
    error_message = "data_store_configs.solution_types must be one or more of [SOLUTION_TYPE_CHAT, SOLUTION_TYPE_GENERATIVE_CHAT, SOLUTION_TYPE_RECOMMENDATION, SOLUTION_TYPE_SEARCH]."
  }
  validation {
    condition = alltrue([
      for k, _ in try(var.data_stores_configs.document_processing_config.parsing_config_overrides, {})
      : contains([
        "docx",
        "html",
        "pdf"
      ], k)
    ])
    error_message = "keys in var.data_stores_configs.document_processing_config.parsing_config_overrides must be one of [docx, html, pdf]."
  }
  validation {
    condition = try(contains(
      ["EXCLUDE", "INCLUDE"],
      var.data_stores_configs.target_site_config
    ), true)
    error_message = "data_store_configs.target_site_config must be one or more of [EXCLUDE, INCLUDE]."
  }
}

variable "chat_agent_configs" {
  description = "The chat agent (Dialogflow CX) configurations."
  type = map(object({
    avatar_uri            = optional(string)
    default_language_code = optional(string)
    description           = optional(string, "Terraform managed.")
    # This overrides the engine location,
    # the datastores location and var.location
    location                 = optional(string)
    supported_language_codes = optional(list(string))
    time_zone                = optional(string)
  }))
}

variable "chat_agent_dlp_security_configs" {
  description = "The DLP security configurations for (Dialogflow CX) chat agents."
  type = object({
    deidentify_template = optional(object({
      deidentify_config = optional(object({

      }))
      description  = optional(string, "Terraform managed.")
      display_name = optional(string)
      parent       = optional(string)
      template_id  = optional(string)
    }))
    inspect_template = optional(object({
      # ["CONTENT_TEXT", "CONTENT_IMA GE"]
      content_options = optional(list(string), [])
      custom_info_types = optional(map(object({
        dictionary = optional(object({
          cloud_storage_path = optional(string)
          words_list         = optional(list(string))
        }))
        # null or EXCLUSION_TYPE_EXCLUDE
        exclusion_type = optional(string)
        # SENSITIVITY_LOW, SENSITIVITY_MODERATE, SENSITIVITY_HIGH
        # VERY_UNLIKELY, UNLIKELY, POSSIBLE, LIKELY, VERY_LIKELY
        likelihood = optional(string, "VERY_LIKELY")
        regex = optional(object({
          # https://github.com/google/re2/wiki/Syntax
          pattern       = string
          group_indexes = optional(list(integer))
        }))
        sensitivity_score = optional(string)
        stored_type_name  = optional(string)
        surrogate_type    = optional(string)
        version           = optional(string)
      })))
      description        = optional(string, "Terraform managed.")
      exclude_info_types = optional(bool, false)
      include_quote      = optional(bool, false)
      # name is the key
      # https://cloud.google.com/dlp/docs/infotypes-reference
      info_types = optional(map(object({
        # SENSITIVITY_LOW, SENSITIVITY_MODERATE, SENSITIVITY_HIGH
        sensitivity_score = optional(string, "SENSITIVITY_MODERATE")
        version           = optional(string)
      })), {})
      limits = optional(object({
        max_findings_per_item    = optional(number, 2000)
        max_findings_per_request = optional(number, 2000)
        # key is the name of the info type
        # https://cloud.google.com/dlp/docs/infotypes-reference
        max_findings_per_info_type = optional(map(object({
          max_findings = optional(number, 2000)
          # SENSITIVITY_LOW, SENSITIVITY_MODERATE, SENSITIVITY_HIGH
          sensitivity_score = optional(string, "SENSITIVITY_MODERATE")
          version           = optional(string)
        })))
      }))
      # VERY_UNLIKELY, UNLIKELY, POSSIBLE, LIKELY, VERY_LIKELY
      min_likelihood = optional(string, "POSSIBLE")
      name           = optional(string)
      parent         = optional(string)
      rule_sets = optional(list(object({
        # name is the key
        # https://cloud.google.com/dlp/docs/infotypes-reference
        info_types = map(object({
          version = optional(string)
          # SENSITIVITY_LOW, SENSITIVITY_MODERATE, SENSITIVITY_HIGH
          sensitivity_score = optional(string, "SENSITIVITY_MODERATE")
        }))
        rules = object({
          exclusion_rule = optional(object({
            # MATCHING_TYPE_FULL_MATCH, MATCHING_TYPE_PARTIAL_MATCH, MATCHING_TYPE_INVERSE_MATCH
            # https://cloud.google.com/dlp/docs/reference/rest/v2/InspectConfig#MatchingType
            matching_type = string
            dictionary = optional(object({
              cloud_storage_path = optional(string)
              words_list         = optional(list(string))
            }))
            regex = optional(object({
              # https://github.com/google/re2/wiki/Syntax
              pattern       = string
              group_indexes = optional(list(integer))
            }))
          }))
          hotward_rule = optional(object({
            hotword_regex = object({
              pattern       = string
              group_indexes = optional(list(integer))
            })
            proximity = object({
              # Either window_before or window_after must be specified
              window_after  = optional(number)
              window_before = optional(number)
            })
          }))
        })
      })), [])
      # [a-zA-Z\d-_]+. The maximum length is 100 characters.
      # Auto-generated if null.
      tempalte_id = optional(string)
    }))
  })
}

variable "engines_configs" {
  description = "The ai-applications engines configurations."
  type = map(object({
    data_store_ids = list(string)
    collection_id  = optional(string, "default_collection")
    chat_engine_config = optional(object({
      agent_config = optional(object({
        avatar_uri            = optional(string)
        default_language_code = optional(string)
        description           = optional(string, "Terraform managed.")
        # Id of an existing agent. It excludes all other options in agent_config
        id = optional(string)
        # This overrides the engine location,
        # the datastores location and var.location
        location                 = optional(string)
        supported_language_codes = optional(list(string))
        time_zone                = optional(string)
      }), {})
      allow_cross_region       = optional(bool, true)
      business                 = optional(string)
      company_name             = optional(string)
      dialogflow_agent_to_link = optional(string)
    }))
    # If industry_vertical and location are not given,
    # they are derived from the first datastore attached
    # to the engines
    industry_vertical = optional(string)
    # This can override var.location and the datastores location
    location = optional(string)
    search_engine_config = optional(object({
      search_add_ons = optional(list(string), [])
      search_tier    = optional(string)
    }))
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for ao in try(var.engines_configs.search_engine_config.search_add_ons, [])
      : contains(["SEARCH_ADD_ON_LLM"], ao)
    ])
    error_message = "Elements in engines_configs.search_engine_config.search_add_ons must be one or more of [SEARCH_ADD_ON_LLM]."
  }
  validation {
    condition = try(contains(
      ["SEARCH_TIER_ENTERPRISE", "SEARCH_TIER_STANDARD"],
      var.engines_configs.search_engine_config.search_tier
    ), true)
    error_message = "engines_configs.search_engine_config.search_tier must be one of [SEARCH_TIER_ENTERPRISE, SEARCH_TIER_STANDARD]."
  }
}

variable "location" {
  description = "Location where the data stores and agents will be created."
  type        = string
  default     = "global"
}

variable "name" {
  description = "The name of the resources."
  type        = string
  nullable    = false
}

variable "project_id" {
  description = "The ID of the project where the data stores and the agents will be created."
  type        = string
  nullable    = false
}
