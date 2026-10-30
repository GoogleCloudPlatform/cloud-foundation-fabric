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

variable "acl_configs" {
  description = "Location-level ACL configurations keyed by location."
  type = map(object({
    idp_config = optional(object({
      external_idp_config = optional(object({
        workforce_pool_name = optional(string)
      }))
      idp_type = optional(string)
    }))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.acl_configs : try(v.idp_config.idp_type, null) == null
      ? true : contains(
        ["GSUITE", "THIRD_PARTY"],
        v.idp_config.idp_type
      )
    ])
    error_message = "acl_configs.*.idp_config.idp_type must be one of [GSUITE, THIRD_PARTY]."
  }
}

variable "chat_agent_security_configs" {
  description = "The DLP security configurations for (Dialogflow CX) chat agents."
  type = object({
    audio_export_settings = optional(object({
      # AUDIO_FORMAT_UNSPECIFIED, MULAW, MP3, OGG
      audio_format = string
      gcs_bucket_config = object({
        # specify an id to use an existing GCS bucket
        id         = optional(string)
        prefix     = string
        location   = optional(string)
        name       = optional(string)
        versioning = optional(bool, true)
      })
      audio_export_pattern   = string
      enable_audio_redaction = optional(bool, false)
    }))
    dlp_deidentify_template = optional(object({
      description  = optional(string, "Terraform managed.")
      display_name = optional(string)
      info_type_transformations = optional(object({
        transformations = list(object({
          info_types = optional(list(object({
            name              = string
            version           = optional(string)
            sensitivity_score = optional(string)
          })))
          primitive_transformation = any
        }))
      }))
      parent = optional(string)
      record_transformations = optional(object({
        field_transformations = optional(list(object({
          fields = list(object({ name = string }))
          condition = optional(object({
            expressions = optional(object({
              logical_operator = optional(string)
              conditions = list(object({
                field    = object({ name = string })
                operator = string
                value = optional(object({
                  integer_value   = optional(number)
                  float_value     = optional(number)
                  string_value    = optional(string)
                  boolean_value   = optional(bool)
                  timestamp_value = optional(string)
                }))
              }))
            }))
          }))
          primitive_transformation = optional(object({
            replace_config = optional(object({
              new_value = object({
                integer_value   = optional(number)
                float_value     = optional(number)
                string_value    = optional(string)
                boolean_value   = optional(bool)
                timestamp_value = optional(string)
                time_value = optional(object({
                  hours   = optional(number)
                  minutes = optional(number)
                  seconds = optional(number)
                  nanos   = optional(number)
                }))
                date_value = optional(object({
                  year  = optional(number)
                  month = optional(number)
                  day   = optional(number)
                }))
                day_of_week_value = optional(string)
              })
            }))
            character_mask_config = optional(object({
              masking_character = optional(string)
              number_to_mask    = optional(number)
              reverse_order     = optional(bool)
              characters_to_ignore = optional(object({
                characters_to_skip          = optional(string)
                common_characters_to_ignore = optional(string)
              }))
            }))
            crypto_replace_ffx_fpe_config = optional(object({
              crypto_key = optional(object({
                transient   = optional(object({ name = string }))
                unwrapped   = optional(object({ key = string }))
                kms_wrapped = optional(object({ wrapped_key = string, crypto_key_name = string }))
              }))
              context = optional(object({ name = optional(string) }))
              surrogate_info_type = optional(object({
                name              = optional(string)
                version           = optional(string)
                sensitivity_score = optional(string)
              }))
              common_alphabet = optional(string)
              custom_alphabet = optional(string)
              radix           = optional(number)
            }))
            # I'll use 'any' for the rest of primitive transformations here to keep it within reason,
            # as they are less common in field transformations compared to masking/redaction/replacement.
            # Actually, let's just include them as 'any' to save space but allow them.
            crypto_deterministic_config = optional(any)
            replace_dictionary_config   = optional(any)
            date_shift_config           = optional(any)
            fixed_size_bucketing_config = optional(any)
            bucketing_config            = optional(any)
            time_part_config            = optional(any)
            redact_config               = optional(bool)
            crypto_hash_config          = optional(any)
          }))
          info_type_transformations = optional(object({
            transformations = list(object({
              info_types = optional(list(object({
                name              = string
                version           = optional(string)
                sensitivity_score = optional(string)
              })))
              primitive_transformation = optional(any)
            }))
          }))
        })))
        record_suppressions = optional(list(object({
          condition = optional(object({
            expressions = optional(object({
              logical_operator = optional(string)
              conditions = list(object({
                field    = object({ name = string })
                operator = string
                value = optional(object({
                  integer_value   = optional(number)
                  float_value     = optional(number)
                  string_value    = optional(string)
                  boolean_value   = optional(bool)
                  timestamp_value = optional(string)
                }))
              }))
            }))
          }))
        })))
      }))
      template_id = optional(string)
    }))
    dlp_inspect_template = optional(object({
      # ["CONTENT_TEXT", "CONTENT_IMAGE"]
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
          group_indexes = optional(list(number))
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
      rule_sets = optional(map(object({
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
              group_indexes = optional(list(number))
            }))
          }))
          hotword_rule = optional(object({
            hotword_regex = object({
              pattern       = string
              group_indexes = optional(list(number))
            })
            proximity = object({
              # Either window_before or window_after must be specified
              window_after  = optional(number)
              window_before = optional(number)
            })
            likelihood_adjustment = optional(object({
              fixed_likelihood    = optional(string)
              relative_likelihood = optional(number)
            }))
          }))
        })
      })), {})
      # [a-zA-Z\d-_]+. The maximum length is 100 characters.
      # Auto-generated if null.
      template_id = optional(string)
    }))
    enable_insights_export = optional(bool, false)
    location               = optional(string)
    purge_data_types       = optional(list(string))
    redaction_scope        = optional(string)
    redaction_strategy     = optional(string)
    retention_window_days  = optional(number)
  })
  nullable = false
  default  = {}
  validation {
    condition = try(var.chat_agent_security_configs.dlp_inspect_template.min_likelihood == null ? true : contains(
      ["VERY_UNLIKELY", "UNLIKELY", "POSSIBLE", "LIKELY", "VERY_LIKELY"],
      var.chat_agent_security_configs.dlp_inspect_template.min_likelihood
    ), true)
    error_message = "inspect_template.min_likelihood must be one of [VERY_UNLIKELY, UNLIKELY, POSSIBLE, LIKELY, VERY_LIKELY]."
  }
  validation {
    condition = alltrue([
      for k, v in try(var.chat_agent_security_configs.dlp_inspect_template.custom_info_types, {}) : v.likelihood == null ? true : contains(
        ["VERY_UNLIKELY", "UNLIKELY", "POSSIBLE", "LIKELY", "VERY_LIKELY"],
        v.likelihood
      )
    ])
    error_message = "inspect_template.custom_info_types.*.likelihood must be one of [VERY_UNLIKELY, UNLIKELY, POSSIBLE, LIKELY, VERY_LIKELY]."
  }
  validation {
    condition = alltrue([
      for k, v in try(var.chat_agent_security_configs.dlp_inspect_template.rule_sets, {}) : try(v.rules.exclusion_rule.matching_type == null ? true : contains(
        ["MATCHING_TYPE_FULL_MATCH", "MATCHING_TYPE_PARTIAL_MATCH", "MATCHING_TYPE_INVERSE_MATCH"],
        v.rules.exclusion_rule.matching_type
      ), true)
    ])
    error_message = "inspect_template.rule_sets.*.rules.exclusion_rule.matching_type must be one of [MATCHING_TYPE_FULL_MATCH, MATCHING_TYPE_PARTIAL_MATCH, MATCHING_TYPE_INVERSE_MATCH]."
  }
  validation {
    condition = alltrue([
      for k, v in try(var.chat_agent_security_configs.dlp_inspect_template.custom_info_types, {}) : v.exclusion_type == null ? true : contains(
        ["EXCLUSION_TYPE_EXCLUDE"],
        v.exclusion_type
      )
    ])
    error_message = "inspect_template.custom_info_types.*.exclusion_type must be EXCLUSION_TYPE_EXCLUDE."
  }
  validation {
    condition = alltrue([
      for k, v in try(var.chat_agent_security_configs.dlp_inspect_template.info_types, {}) : v.sensitivity_score == null ? true : contains(
        ["SENSITIVITY_LOW", "SENSITIVITY_MODERATE", "SENSITIVITY_HIGH"],
        v.sensitivity_score
      )
    ])
    error_message = "inspect_template.info_types.*.sensitivity_score must be one of [SENSITIVITY_LOW, SENSITIVITY_MODERATE, SENSITIVITY_HIGH]."
  }
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    kms_keys    = optional(map(string), {})
    locations   = optional(map(string), {})
    project_ids = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

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
    kms_key                      = optional(string)
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
    condition = alltrue([
      for k, v in var.data_stores_configs : contains(
        ["CONTENT_REQUIRED", "NO_CONTENT", "PUBLIC_WEBSITE"],
        v.content_config
      )
    ])
    error_message = "data_store_configs.content_config must be one of [CONTENT_REQUIRED, NO_CONTENT, PUBLIC_WEBSITE]."
  }
  validation {
    condition = alltrue([
      for k, v in var.data_stores_configs : contains(
        ["GENERIC", "HEALTHCARE_FHIR", "MEDIA"],
        v.industry_vertical
      )
    ])
    error_message = "data_store_configs.industry_vertical must be one of [GENERIC, HEALTHCARE_FHIR, MEDIA]."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.data_stores_configs : [
        for st in try(v.solution_types, []) : contains([
          "SOLUTION_TYPE_CHAT",
          "SOLUTION_TYPE_GENERATIVE_CHAT",
          "SOLUTION_TYPE_RECOMMENDATION",
          "SOLUTION_TYPE_SEARCH"
        ], st)
      ]
    ]))
    error_message = "data_store_configs.solution_types must be one or more of [SOLUTION_TYPE_CHAT, SOLUTION_TYPE_GENERATIVE_CHAT, SOLUTION_TYPE_RECOMMENDATION, SOLUTION_TYPE_SEARCH]."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.data_stores_configs : [
        for po_k, po_v in try(v.document_processing_config.parsing_config_overrides, {}) : contains([
          "docx",
          "html",
          "pdf"
        ], po_k)
      ]
    ]))
    error_message = "keys in var.data_stores_configs.document_processing_config.parsing_config_overrides must be one of [docx, html, pdf]."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.data_stores_configs : [
        for ts_k, ts_v in try(v.sites_search_config.target_sites, {}) : contains([
          "EXCLUDE",
          "INCLUDE"
        ], ts_v.type)
      ]
    ]))
    error_message = "data_store_configs.sites_search_config.target_sites.*.type must be one of [EXCLUDE, INCLUDE]."
  }
}

variable "encryption_configs" {
  description = "CMEK configurations registered for the project, keyed by location (e.g. us, eu). Data stores and engines are created after keys are registered. KMS key format: 'projects/[PROJECT]/locations/[LOCATION]/keyRings/[RING]/cryptoKeys/[KEY_NAME]'."
  type = map(object({
    kms_key            = string
    set_default        = optional(bool, true)
    single_region_keys = optional(list(string), [])
  }))
  default  = {}
  nullable = false
}

variable "engines_configs" {
  description = "The AI applications engines configurations."
  type = object({
    chat_engine_config = optional(object({
      agent_config = optional(object({
        avatar_uri            = optional(string)
        default_language_code = optional(string)
        description           = optional(string, "Terraform managed.")
        # Id of an existing agent. The agent will be created otherwise.
        id = optional(string)
        # This overrides the engine location,
        # the datastores location and var.location
        location = optional(string)
        security_settings_config = optional(object({
          create = optional(bool, false)
          id     = optional(string)
        }))
        supported_language_codes = optional(list(string))
        time_zone                = optional(string)
      }), {})
      allow_cross_region = optional(bool, true)
      business           = optional(string)
      company_name       = optional(string)
    }))
    collection_id  = optional(string, "default_collection")
    data_store_ids = optional(list(string), [])
    # If industry_vertical and location are not given,
    # they are derived from the first datastore attached
    # to the engines
    industry_vertical = optional(string)
    # This can override var.location and the datastores location
    location = optional(string)
    search_engine_config = optional(object({
      app_type = optional(string)
      assistant_config = optional(object({
        assistant_id = optional(string, "default_assistant")
        customer_policy = optional(object({
          banned_phrases = optional(list(object({
            ignore_diacritics = optional(bool)
            match_type        = optional(string)
            phrase            = string
          })), [])
          model_armor_config = optional(object({
            failure_mode         = optional(string)
            response_template    = string
            user_prompt_template = string
          }))
        }))
        description  = optional(string)
        display_name = optional(string)
        generation_config = optional(object({
          default_language = optional(string)
          system_instruction = optional(object({
            additional_system_instruction = optional(string)
          }))
        }))
        web_grounding_type = optional(string)
      }))
      company_name               = optional(string)
      disable_analytics          = optional(bool)
      features                   = optional(map(string))
      kms_key                    = optional(string)
      required_subscription_tier = optional(string)
      search_add_ons             = optional(list(string), [])
      search_tier                = optional(string)
      widget_config = optional(object({
        access_settings = optional(object({
          allow_public_access              = optional(bool)
          allowlisted_domains              = optional(list(string))
          enable_web_app                   = optional(bool)
          language_code                    = optional(string)
          workforce_identity_pool_provider = optional(string)
        }))
        homepage_setting = optional(object({
          shortcuts = optional(list(object({
            destination_uri = optional(string)
            icon_url        = optional(string)
            title           = optional(string)
          })), [])
        }))
        ui_branding = optional(object({
          logo = optional(object({
            url = optional(string)
          }))
        }))
        ui_settings = optional(object({
          data_store_ui_configs = optional(list(object({
            facet_field = optional(list(object({
              display_name = optional(string)
              field        = string
            })), [])
            fields_ui_components_map = optional(list(object({
              device_visibility = optional(list(string))
              display_template  = optional(string)
              field             = string
              ui_component      = string
            })), [])
            name = string
          })), [])
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
        }))
        widget_config_id = optional(string, "default_search_widget_config")
      }))
    }))
  })
  nullable = false
  default  = {}
  validation {
    condition = (
      var.engines_configs.chat_engine_config == null
      && var.engines_configs.search_engine_config == null
      ? true
      : length(var.engines_configs.data_store_ids) > 0 ? true : false
    )
    error_message = "You must specify at least one data store id for each engine."
  }
  validation {
    condition = alltrue([
      for ao in try(var.engines_configs.search_engine_config.search_add_ons, [])
      : contains(["SEARCH_ADD_ON_LLM"], ao)
    ])
    error_message = "Elements in engines_configs.search_engine_config.search_add_ons must be one or more of [SEARCH_ADD_ON_LLM]."
  }
  validation {
    condition = alltrue([
      try(var.engines_configs.search_engine_config.search_tier, null) == null
      ? true : contains(
        ["SEARCH_TIER_ENTERPRISE", "SEARCH_TIER_STANDARD"],
        var.engines_configs.search_engine_config.search_tier
      ), true
    ])
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

variable "user_stores_configs" {
  description = "Location-level user store configurations keyed by location."
  type = map(object({
    default_license_config             = optional(string)
    enable_expired_license_auto_update = optional(bool)
    enable_license_auto_register       = optional(bool)
  }))
  default  = {}
  nullable = false
}
