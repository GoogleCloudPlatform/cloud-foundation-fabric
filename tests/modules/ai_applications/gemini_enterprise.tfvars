context = {
  kms_keys = {
    eu = "projects/kms-project/locations/eu/keyRings/ring/cryptoKeys/key"
  }
  locations = {
    primary = "eu"
  }
  project_ids = {
    app = "actual-project-id"
  }
}
name       = "my-gemini-app"
project_id = "$project_ids:app"
location   = "$locations:primary"
acl_configs = {
  "$locations:primary" = {
    idp_config = {
      external_idp_config = {
        workforce_pool_name = "locations/global/workforcePools/my-pool"
      }
      idp_type = "THIRD_PARTY"
    }
  }
}
user_stores_configs = {
  "$locations:primary" = {
    default_license_config             = "projects/actual-project-id/locations/eu/userStores/default_user_store/licenseConfigs/default"
    enable_expired_license_auto_update = true
    enable_license_auto_register       = true
  }
}
encryption_configs = {
  "$locations:primary" = {
    kms_key = "$kms_keys:eu"
  }
}
data_stores_configs = {
  data-store-1 = {
    kms_key        = "$kms_keys:eu"
    location       = "$locations:primary"
    solution_types = ["SOLUTION_TYPE_SEARCH"]
  }
}
engines_configs = {
  data_store_ids = ["data-store-1"]
  location       = "$locations:primary"
  search_engine_config = {
    app_type          = "APP_TYPE_INTRANET"
    company_name      = "Example"
    disable_analytics = false
    features = {
      agent-sharing-without-admin-approval = "FEATURE_STATE_ON"
    }
    kms_key                    = "$kms_keys:eu"
    required_subscription_tier = "SUBSCRIPTION_TIER_ENTERPRISE"
    search_add_ons             = ["SEARCH_ADD_ON_LLM"]
    search_tier                = "SEARCH_TIER_ENTERPRISE"
    assistant_config = {
      customer_policy = {
        banned_phrases = [{
          ignore_diacritics = true
          match_type        = "SIMPLE_STRING_MATCH"
          phrase            = "confidential"
        }]
        model_armor_config = {
          failure_mode         = "FAIL_OPEN"
          response_template    = "projects/actual-project-id/locations/eu/templates/resp-tmpl"
          user_prompt_template = "projects/actual-project-id/locations/eu/templates/prompt-tmpl"
        }
      }
      description  = "Enterprise Assistant"
      display_name = "Enterprise Assistant"
      generation_config = {
        default_language = "en"
        system_instruction = {
          additional_system_instruction = "Answer concisely."
        }
      }
      web_grounding_type = "WEB_GROUNDING_TYPE_GOOGLE_SEARCH"
    }
    widget_config = {
      access_settings = {
        allow_public_access              = false
        allowlisted_domains              = ["example.com"]
        enable_web_app                   = true
        language_code                    = "en-US"
        workforce_identity_pool_provider = "locations/global/workforcePools/my-pool/providers/my-provider"
      }
      homepage_setting = {
        shortcuts = [{
          destination_uri = "https://intranet.example.com"
          icon_url        = "https://intranet.example.com/icon.png"
          title           = "Intranet"
        }]
      }
      ui_branding = {
        logo = {
          url = "https://intranet.example.com/logo.png"
        }
      }
      ui_settings = {
        data_store_ui_configs = [{
          facet_field = [{
            display_name = "Department"
            field        = "department"
          }]
          fields_ui_components_map = [{
            device_visibility = ["DESKTOP", "MOBILE"]
            display_template  = "{value}"
            field             = "title"
            ui_component      = "TITLE"
          }]
          name = "projects/actual-project-id/locations/eu/collections/default_collection/dataStores/my-gemini-app-data-store-1"
        }]
        default_search_request_order_by = "relevance"
        disable_user_events_collection  = false
        enable_autocomplete             = true
        enable_create_agent_button      = true
        enable_people_search            = true
        enable_quality_feedback         = true
        enable_safe_search              = true
        enable_search_as_you_type       = true
        enable_visual_content_summary   = true
        generative_answer_config = {
          disable_related_questions       = false
          ignore_adversarial_query        = true
          ignore_low_relevant_content     = true
          ignore_non_answer_seeking_query = true
          image_source                    = "ALL_AVAILABLE_SOURCES"
          language_code                   = "en"
          max_rephrase_steps              = 2
          model_prompt_preamble           = "Use internal docs."
          model_version                   = "stable"
          result_count                    = 5
        }
        interaction_type        = "SEARCH_WITH_FOLLOW_UPS"
        result_description_type = "SNIPPET"
      }
    }
  }
}
