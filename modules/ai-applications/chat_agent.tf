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

resource "google_dialogflow_cx_agent" "default" {
  for_each = ({
    for k, v in var.engines_configs
    : k => v if(
      v.chat_engine_config != null
      && v.chat_engine_config.agent_config.id == null
    )
  })
  display_name                   = "${var.name}-${each.key}"
  project                        = var.project_id
  description                    = each.value.chat_engine_config.agent_config.description
  default_language_code          = each.value.chat_engine_config.agent_config.default_language_code
  time_zone                      = each.value.chat_engine_config.agent_config.time_zone
  supported_language_codes       = each.value.chat_engine_config.agent_config.supported_language_codes
  avatar_uri                     = each.value.chat_engine_config.agent_config.avatar_uri
  enable_spell_correction        = each.value.chat_engine_config.agent_config.enable_spell_correction
  start_playbook                 = each.value.chat_engine_config.agent_config.start_playbook
  enable_multi_language_training = each.value.chat_engine_config.agent_config.enable_multi_language_training
  locked                         = each.value.chat_engine_config.agent_config.locked
  delete_chat_engine_on_destroy  = each.value.chat_engine_config.agent_config.delete_chat_engine_on_destroy
  location = coalesce(
    try(each.value.chat_engine_config.agent_config.location, null),
    try(google_discovery_engine_data_store.default[each.value.data_store_ids[0]].location, null),
    var.location
  )
  security_settings = try(
    google_dialogflow_cx_security_settings.security_settings[each.value.chat_engine_config.agent_config.default].id,
    each.value.chat_engine_config.agent_config.security_settings
  )

  dynamic "advanced_settings" {
    for_each = (
      each.value.chat_engine_config.agent_config.advanced_settings == null
      ? {} : { 1 = 1 }
    )

    content {

      dynamic "audio_export_gcs_destination" {
        for_each = (
          each.value.chat_engine_config.agent_config.advanced_settings.audio_export_gcs_destination_uri == null
          ? {} : { 1 = 1 }
        )

        content {
          uri = each.value.chat_engine_config.agent_config.advanced_settings.audio_export_gcs_destination_uri
        }
      }

      dynamic "speech_settings" {
        for_each = (
          each.value.chat_engine_config.agent_config.advanced_settings.speech_settings == null
          ? {} : { 1 = 1 }
        )

        content {
          endpointer_sensitivity        = each.value.chat_engine_config.agent_config.advanced_settings.speech_settings.endpointer_sensitivity
          no_speech_timeout             = each.value.chat_engine_config.agent_config.advanced_settings.speech_settings.no_speech_timeout
          use_timeout_based_endpointing = each.value.chat_engine_config.agent_config.advanced_settings.speech_settings.use_timeout_based_endpointing
          models                        = each.value.chat_engine_config.agent_config.advanced_settings.speech_settings.models
        }
      }

      dynamic "dtmf_settings" {
        for_each = (
          each.value.chat_engine_config.agent_config.advanced_settings.dtmf_settings == null
          ? {} : { 1 = 1 }
        )

        content {
          enabled      = true
          max_digits   = each.value.chat_engine_config.agent_config.advanced_settings.dtmf_settings.max_digits
          finish_digit = each.value.chat_engine_config.agent_config.advanced_settings.dtmf_settings.finish_digit
        }
      }

      dynamic "logging_settings" {
        for_each = each.value.chat_engine_config.agent_config.advanced_settings.logging_settings == null ? {} : { 1 = 1 }

        content {
          enable_stackdriver_logging     = each.value.chat_engine_config.agent_config.advanced_settings.enable_stackdriver_logging
          enable_interaction_logging     = each.value.chat_engine_config.agent_config.advanced_settings.enable_interaction_logging
          enable_consent_based_redaction = each.value.chat_engine_config.agent_config.advanced_settings.enable_consent_based_redaction
        }
      }
    }
  }

  dynamic "speech_to_text_settings" {
    for_each = (
      each.value.chat_engine_config.agent_config.enable_speech_adaptation == null
      ? {} : { 1 = 1 }
    )

    content {
      enable_speech_adaptation = true
    }
  }

  dynamic "git_integration_settings" {
    for_each = (
      each.value.chat_engine_config.agent_config.git_config == null
      ? {} : { 1 = 1 }
    )

    content {
      github_settings {
        display_name = coalesce(
          each.value.chat_engine_config.agent_config.git_config.display_name,
          var.name
        )
        repository_uri  = each.value.chat_engine_config.agent_config.repository_uri
        tracking_branch = each.value.chat_engine_config.agent_config.tracking_branch
        access_token    = each.value.chat_engine_config.agent_config.access_token
        branches        = each.value.chat_engine_config.agent_config.branches
      }
    }
  }

  dynamic "text_to_speech_settings" {
    for_each = (
      each.value.chat_engine_config.agent_config.synthesize_speech_configs == null
      ? {} : { 1 = 1 }
    )

    content {
      synthesize_speech_configs = each.value.chat_engine_config.agent_config.synthesize_speech_configs
    }
  }

  dynamic "gen_app_builder_settings" {
    for_each = (
      each.value.chat_engine_config.agent_config.gen_app_builder_engine_id == null
      ? {} : { 1 = 1 }
    )

    content {
      engine = each.value.chat_engine_config.agent_config.gen_app_builder_engine_id
    }
  }

  dynamic "answer_feedback_settings" {
    for_each = (
      each.value.chat_engine_config.agent_config.enable_answer_feedback == null
      ? {} : { 1 = 1 }
    )

    content {
      enable_answer_feedback = each.value.chat_engine_config.agent_config.enable_answer_feedback
    }
  }

  dynamic "personalization_settings" {
    for_each = (
      each.value.chat_engine_config.agent_config.default_end_user_metadata == null
      ? {} : { 1 = 1 }
    )

    content {
      default_end_user_metadata = each.value.chat_engine_config.agent_config.default_end_user_metadata
    }
  }

  dynamic "client_certificate_settings" {
    for_each = (
      each.value.chat_engine_config.agent_config.client_certificate_settings == null
      ? {} : { 1 = 1 }
    )

    content {
      ssl_certificate = each.value.chat_engine_config.agent_config.client_certificate_settings.ssl_certificate
      private_key     = each.value.chat_engine_config.agent_config.client_certificate_settings.private_key
      passphrase      = each.value.chat_engine_config.agent_config.client_certificate_settings.passphrase
    }
  }
}

resource "google_dialogflow_cx_security_settings" "default" {
  for_each            = var.chat_engine_agents_security_settings
  display_name        = each.key
  location            = coalesce(each.location, var.location)
  redaction_strategy  = each.value.redirection_strategy
  redaction_scope     = each.value.redaction_scope
  inspect_template    = google_data_loss_prevention_inspect_template.default.id
  deidentify_template = google_data_loss_prevention_deidentify_template.default.id
  purge_data_types    = each.value.purge_data_types
  retention_strategy  = each.value.retention_strategy

  audio_export_settings {
    for_each = each.value.audio_export_settings == null ? {} : { 1 = 1 }

    content {
      gcs_bucket             = google_storage_bucket.bucket.id
      audio_export_pattern   = each.value.audio_export_settings.audio_export_pattern
      enable_audio_redaction = each.value.audio_export_settings.enable_audio_redaction
      audio_format           = each.value.audio_export_settings.audio_format
    }
  }

  dynamic "insights_export_settings" {
    for_each = (
      each.value.enable_insights_export == null
      || each.value.enable_insights_export == false
      ? {} : { 1 = 1 }
    )

    content {
      enable_insights_export = true
    }
  }
}

resource "google_data_loss_prevention_inspect_template" "default" {
  template_id    = var.chat_agent_dlp_security_configs.inspect_template.template_id
  display_name   = coalesce(var.chat_agent_dlp_security_configs.name, var.name)
  description    = var.chat_agent_dlp_security_configs.inspect_template.description
  min_likelihood = var.chat_agent_dlp_security_configs.inspect_template.min_likelihood
  parent = coalesce(
    var.chat_agent_dlp_security_configs.inspect_template.parent,
    "projects/${var.project_id}"
  )

  inspect_config {
    exclude_info_types = var.chat_agent_dlp_security_configs.inspect_template.exclude_info_types
    include_quote      = var.chat_agent_dlp_security_configs.inspect_template.include_quote
    min_likelihood     = var.chat_agent_dlp_security_configs.inspect_template.min_likelihood
    content_options    = var.chat_agent_dlp_security_configs.inspect_template.content_options

    dynamic "info_types" {
      for_each = var.chat_agent_dlp_security_configs.inspect_template.custom_info_types

      content {
        name             = info_types.key
        sensitiviy_score = info_types.value.sensitiviy_score
        version          = info_types.value.version
      }
    }

    dynamic "custom_info_types" {
      for_each = var.chat_agent_dlp_security_configs.inspect_template.info_types

      content {
        exclusion_type = info_types.value.exclusion_type
        likelihood     = info_types.value.likelihood
        surrogate_type = info_types.value.surrogate_type

        info_type {
          name             = info_types.key
          sensitiviy_score = info_types.value.sensitiviy_score
          version          = info_types.value.version
        }

        dynamic "regex" {
          for_each = info_types.value.regex == null ? {} : { 1 = 1 }

          content {
            group_indexes = info_types.value.regex.group_indexes
            pattern       = info_types.value.regex.pattern
          }
        }

        dynamic "sensitivity_score" {
          for_each = info_types.value.sensitivity_score == null ? {} : { 1 = 1 }

          content {
            score = info_types.value.sensitivity_score
          }
        }

        dynamic "stored_type" {
          for_each = info_types.value.stored_type_name == null ? {} : { 1 = 1 }

          content {
            name = info_types.value.stored_type_name
          }
        }

        dynamic "dictionary" {
          for_each = info_types.value.dictionary == null ? {} : { 1 = 1 }

          content {

            dynamic "cloud_storage_path" {
              for_each = (
                info_types.value.dictionary.cloud_storage_path == null
                ? {} : { 1 = 1 }
              )

              content {
                path = info_types.value.dictionary.cloud_storage_path
              }
            }

            dynamic "word_list" {
              for_each = (
                info_types.value.dictionary.word_list == null ? {} : { 1 = 1 }
              )

              content {
                words = info_types.value.dictionary.word_list
              }
            }
          }
        }
      }
    }

    dynamic "limits" {
      for_each = var.chat_agent_dlp_security_configs.inspect_template.limits

      content {
        max_findings_per_item    = limits.max_findings_per_item
        max_findings_per_request = limits.value.max_findings_per_request

        dynamic "max_findings_per_info_type" {
          for_each = limits.value.max_findings_per_info_type

          content {
            max_findings = max_findings_per_info_type.value.max_findings

            info_type {
              name             = max_findings_per_info_type.key
              sensitiviy_score = max_findings_per_info_type.value.sensitiviy_score
              version          = max_findings_per_info_type.value.version
            }
          }
        }
      }
    }

    dynamic "rule_set" {
      for_each = toset(var.chat_agent_dlp_security_configs.rule_sets)

      content {
        dynamic "info_types" {
          for_each = rule_set.value.info_types

          content {
            name             = info_types.key
            sensitiviy_score = info_types.value.sensitiviy_score
            version          = info_types.value.version
          }
        }

        rules {
          dynamic "exclusion_rule" {
            for_each = (
              info_types.value.rules.exclusion_rule == null
              ? {} : { 1 = 1 }
            )

            content {
              matching_type = info_types.value.rules.exclusion_rule.matching_type

              dynamic "dictionary" {
                for_each = (
                  info_types.value.rules.exclusion_rule.dictionary == null
                  ? {} : { 1 = 1 }
                )

                content {
                  cloud_storage_path = info_types.value.rules.exclusion_rule.dictionary.cloud_storage_path
                  words_list         = info_types.value.rules.exclusion_rule.dictionary.words_list
                }
              }

              dynamic "regex" {
                for_each = (
                  info_types.value.rules.exclusion_rule.regex == null
                  ? {} : { 1 = 1 }
                )

                content {
                  pattern       = info_types.value.rules.exclusion_rule.regex.pattern
                  group_indexes = info_types.value.rules.exclusion_rule.regex.group_indexes
                }
              }
            }
          }

          dynamic "hotword_rule" {
            for_each = (
              info_types.value.rules.hotword == null
              ? {} : { 1 = 1 }
            )

            content {
              dynamic "hotword_regex" {
                for_each = (
                  info_types.value.rules.hotword.hotword_regex == null
                  ? {} : { 1 = 1 }
                )

                content {
                  pattern       = info_types.value.rules.hotword.hotword_regex.pattern
                  group_indexes = info_types.value.rules.hotword.hotword_regex.group_indexes
                }
              }

              dynamic "proximity" {
                for_each = (
                  info_types.value.rules.hotword.proximity == null
                  ? {} : { 1 = 1 }
                )

                content {
                  window_after  = info_types.value.rules.hotword.proximity.window_after
                  window_before = info_types.value.rules.hotword.proximity.window_before
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "google_data_loss_prevention_deidentify_template" "default" {
  parent = coalesce(
    var.chat_agent_dlp_security_configs.deidentify_template.parent,
    "projects/${var.project_id}"
  )
  display_name = each.key

  deidentify_config {

    info_type_transformations {

      transformations {

        primitive_transformation {

          replace_config {

            new_value {
              string_value = "[REDACTED]"
            }
          }
        }
      }
    }
  }
}

