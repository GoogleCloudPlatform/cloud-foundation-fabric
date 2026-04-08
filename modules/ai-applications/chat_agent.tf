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
  count = (
    var.engines_configs.chat_engine_config != null
    && try(var.engines_configs.chat_engine_config.agent_config.id, null) == null
    ? 1 : 0
  )
  display_name             = var.name
  project                  = var.project_id
  description              = var.engines_configs.chat_engine_config.agent_config.description
  default_language_code    = coalesce(var.engines_configs.chat_engine_config.agent_config.default_language_code, "en")
  time_zone                = coalesce(var.engines_configs.chat_engine_config.agent_config.time_zone, "America/Los_Angeles")
  supported_language_codes = var.engines_configs.chat_engine_config.agent_config.supported_language_codes
  avatar_uri               = var.engines_configs.chat_engine_config.agent_config.avatar_uri
  location = coalesce(
    try(var.engines_configs.chat_engine_config.agent_config.location, null),
    try(google_discovery_engine_data_store.default[var.engines_configs.data_store_ids[0]].location, null),
    var.location
  )
  security_settings = try(
    coalesce(
      try(var.engines_configs.chat_engine_config.agent_config.security_settings_config.id, null),
      try(google_dialogflow_cx_security_settings.default[0].id, null)
    ),
    null
  )
}

resource "google_dialogflow_cx_security_settings" "default" {
  count = (
    try(var.engines_configs.chat_engine_config.agent_config.security_settings_config.id == null)
    && try(var.engines_configs.chat_engine_config.agent_config.security_settings_config.create, false)
    ? 1 : 0
  )
  display_name          = var.name
  project               = var.project_id
  location              = coalesce(var.chat_agent_security_configs.location, var.location)
  redaction_strategy    = var.chat_agent_security_configs.redaction_strategy
  redaction_scope       = var.chat_agent_security_configs.redaction_scope
  inspect_template      = try(google_data_loss_prevention_inspect_template.default[0].id, null)
  deidentify_template   = try(google_data_loss_prevention_deidentify_template.default[0].id, null)
  purge_data_types      = var.chat_agent_security_configs.purge_data_types
  retention_window_days = var.chat_agent_security_configs.retention_window_days

  dynamic "audio_export_settings" {
    for_each = (
      var.chat_agent_security_configs.audio_export_settings == null
      ? {} : { 1 = 1 }
    )

    content {
      gcs_bucket = (
        google_storage_bucket.bucket.id
      )
      audio_export_pattern   = var.chat_agent_security_configs.audio_export_settings.audio_export_pattern
      enable_audio_redaction = var.chat_agent_security_configs.audio_export_settings.enable_audio_redaction
      audio_format           = var.chat_agent_security_configs.audio_export_settings.audio_format
    }
  }

  dynamic "insights_export_settings" {
    for_each = (
      var.chat_agent_security_configs.enable_insights_export == null
      || var.chat_agent_security_configs.enable_insights_export == false
      ? {} : { 1 = 1 }
    )

    content {
      enable_insights_export = true
    }
  }
}

module "audio_export_settings_bucket" {
  count = (
    var.chat_agent_security_configs.audio_export_settings == null
    || try(var.chat_agent_security_configs.audio_export_settings.id, null) != null
  ) ? 0 : 1
  source     = "../gcs"
  project_id = var.project_id
  prefix     = var.chat_agent_security_configs.audio_export_settings.gcs_bucket_config.prefix
  name = try(
    var.chat_agent_security_configs.audio_export_settings.gcs_bucket_config.prefix,
    var.name
  )
  location = coalesce(
    try(var.chat_agent_security_configs.audio_export_settings.gcs_bucket_config.location),
    var.location
  )
  versioning = var.chat_agent_security_configs.audio_export_settings.gcs_bucket_config.versioning
}

resource "google_data_loss_prevention_inspect_template" "default" {
  count = (
    try(var.engines_configs.chat_engine_config.agent_config.security_settings_config.dlp_inspect_template, null) == null
    ? 0 : 1
  )
  template_id  = var.chat_agent_security_configs.dlp_inspect_template.template_id
  display_name = var.name
  description  = var.chat_agent_security_configs.dlp_inspect_template.description
  parent = coalesce(
    var.chat_agent_security_configs.dlp_inspect_template.parent,
    "projects/${var.project_id}"
  )

  inspect_config {
    exclude_info_types = var.chat_agent_security_configs.dlp_inspect_template.exclude_info_types
    include_quote      = var.chat_agent_security_configs.dlp_inspect_template.include_quote
    min_likelihood     = var.chat_agent_security_configs.dlp_inspect_template.min_likelihood
    content_options    = var.chat_agent_security_configs.dlp_inspect_template.content_options

    dynamic "info_types" {
      for_each = try(var.chat_agent_security_configs.dlp_inspect_template.custom_info_types, {})

      content {
        name    = info_types.key
        version = info_types.value.version

        dynamic "sensitivity_score" {
          for_each = info_types.value.sensitivity_score == null ? [] : [1]

          content {
            score = info_types.value.sensitivity_score
          }
        }
      }
    }

    dynamic "custom_info_types" {
      for_each = (
        try(var.chat_agent_security_configs.dlp_inspect_template.info_types,
        {})
      )
      iterator = info_types

      content {
        exclusion_type = info_types.value.exclusion_type
        likelihood     = info_types.value.likelihood

        dynamic "surrogate_type" {
          for_each = info_types.value.surrogate_type == null ? {} : { 1 = 1 }

          content {}
        }

        info_type {
          name    = info_types.key
          version = info_types.value.version

          dynamic "sensitivity_score" {
            for_each = (
              info_types.value.sensitivity_score == null
              ? {} : { 1 = 1 }
            )

            content {
              score = info_types.value.sensitivity_score
            }
          }
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
      for_each = (
        var.chat_agent_security_configs.dlp_inspect_template.limits == null
        ? [] : [var.chat_agent_security_configs.dlp_inspect_template.limits]
      )

      content {
        max_findings_per_item    = limits.value.max_findings_per_item
        max_findings_per_request = limits.value.max_findings_per_request

        dynamic "max_findings_per_info_type" {
          for_each = limits.value.max_findings_per_info_type

          content {
            max_findings = max_findings_per_info_type.value.max_findings

            info_type {
              name    = max_findings_per_info_type.key
              version = max_findings_per_info_type.value.version

              dynamic "sensitivity_score" {
                for_each = (
                  max_findings_per_info_type.value.sensitivity_score == null
                  ? {} : { 1 = 1 }
                )

                content {
                  score = max_findings_per_info_type.value.sensitivity_score
                }
              }
            }
          }
        }
      }
    }

    dynamic "rule_set" {
      for_each = (
        var.chat_agent_security_configs.dlp_inspect_template.rule_sets
      )

      content {
        dynamic "info_types" {
          for_each = rule_set.value.info_types

          content {
            name    = info_types.key
            version = info_types.value.version

            dynamic "sensitivity_score" {
              for_each = (
                info_types.value.sensitivity_score == null
                ? {} : { 1 = 1 }
              )

              content {
                score = info_types.value.sensitivity_score
              }
            }
          }
        }

        rules {
          dynamic "exclusion_rule" {
            for_each = (
              rule_set.value.rules.exclusion_rule == null
              ? {} : { 1 = 1 }
            )

            content {
              matching_type = rule_set.value.rules.exclusion_rule.matching_type

              dynamic "dictionary" {
                for_each = (
                  rule_set.value.rules.exclusion_rule.dictionary == null
                  ? {} : { 1 = 1 }
                )

                content {
                  dynamic "cloud_storage_path" {
                    for_each = (
                      rule_set.value.rules.exclusion_rule.dictionary.cloud_storage_path == null
                      ? {} : { 1 = 1 }
                    )

                    content {
                      path = rule_set.value.rules.exclusion_rule.dictionary.cloud_storage_path
                    }
                  }
                  dynamic "word_list" {
                    for_each = (
                      rule_set.value.rules.exclusion_rule.dictionary.words_list == null
                      ? {} : { 1 = 1 }
                    )

                    content {
                      words = rule_set.value.rules.exclusion_rule.dictionary.words_list
                    }
                  }
                }
              }

              dynamic "regex" {
                for_each = (
                  rule_set.value.rules.exclusion_rule.regex == null
                  ? {} : { 1 = 1 }
                )

                content {
                  pattern       = rule_set.value.rules.exclusion_rule.regex.pattern
                  group_indexes = rule_set.value.rules.exclusion_rule.regex.group_indexes
                }
              }
            }
          }

          dynamic "hotword_rule" {
            for_each = (
              rule_set.value.rules.hotword_rule == null
              ? {} : { 1 = 1 }
            )

            content {
              dynamic "hotword_regex" {
                for_each = (
                  rule_set.value.rules.hotword_rule.hotword_regex == null
                  ? {} : { 1 = 1 }
                )

                content {
                  pattern       = rule_set.value.rules.hotword_rule.hotword_regex.pattern
                  group_indexes = rule_set.value.rules.hotword_rule.hotword_regex.group_indexes
                }
              }

              dynamic "proximity" {
                for_each = (
                  rule_set.value.rules.hotword_rule.proximity == null
                  ? {} : { 1 = 1 }
                )

                content {
                  window_after  = rule_set.value.rules.hotword_rule.proximity.window_after
                  window_before = rule_set.value.rules.hotword_rule.proximity.window_before
                }
              }

              dynamic "likelihood_adjustment" {
                for_each = (
                  rule_set.value.rules.hotword_rule.likelihood_adjustment == null
                  ? [{ fixed_likelihood = "VERY_LIKELY" }]
                  : [rule_set.value.rules.hotword_rule.likelihood_adjustment]
                )

                content {
                  fixed_likelihood    = likelihood_adjustment.value.fixed_likelihood
                  relative_likelihood = likelihood_adjustment.value.relative_likelihood
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
  count = (
    try(var.engines_configs.chat_engine_config.agent_config.security_settings_config.dlp_deidentify_template, null) == null
    ? 0 : 1
  )
  parent = coalesce(
    var.chat_agent_security_configs.dlp_deidentify_template.parent,
    "projects/${var.project_id}"
  )
  display_name = var.name
  description  = var.chat_agent_security_configs.dlp_deidentify_template.description
  template_id  = var.chat_agent_security_configs.dlp_deidentify_template.template_id

  dynamic "deidentify_config" {
    for_each = (
      var.chat_agent_security_configs.dlp_deidentify_template == null
      ? [] : [var.chat_agent_security_configs.dlp_deidentify_template]
    )

    content {
      dynamic "image_transformations" {
        for_each = (
          deidentify_config.value.image_transformations == null
          ? [] : [deidentify_config.value.image_transformations]
        )

        content {
          dynamic "transforms" {
            for_each = image_transformations.value.transforms

            content {
              dynamic "all_info_types" {
                for_each = transforms.value.all_info_types ? { 1 = 1 } : {}

                content {}
              }

              dynamic "all_text" {
                for_each = (
                  transforms.value.all_text ? { 1 = 1 } : {}
                )

                content {}
              }

              dynamic "redaction_color" {
                for_each = (
                  transforms.value.redaction_color == null
                  ? [] : [transforms.value.redaction_color]
                )

                content {
                  blue  = redaction_color.value.blue
                  green = redaction_color.value.green
                  red   = redaction_color.value.red
                }
              }

              dynamic "selected_info_types" {
                for_each = (
                  transforms.value.selected_info_types == null
                  ? [] : [transforms.value.selected_info_types]
                )

                content {
                  dynamic "info_types" {
                    for_each = selected_info_types.value.info_types

                    content {
                      name    = info_types.value.name
                      version = info_types.value.version

                      dynamic "sensitivity_score" {
                        for_each = (
                          info_types.value.sensitivity_score == null
                          ? {} : { 1 = 1 }
                        )

                        content {
                          score = info_types.value.sensitivity_score
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "info_type_transformations" {
        for_each = (
          deidentify_config.value.info_type_transformations == null
          ? [] : [deidentify_config.value.info_type_transformations]
        )

        content {
          dynamic "transformations" {
            for_each = info_type_transformations.value.transformations

            content {
              dynamic "info_types" {
                for_each = (
                  transformations.value.info_types == null
                  ? [] : transformations.value.info_types
                )

                content {
                  name    = info_types.value.name
                  version = info_types.value.version

                  dynamic "sensitivity_score" {
                    for_each = (
                      info_types.value.sensitivity_score == null
                      ? [] : [1]
                    )

                    content {
                      score = info_types.value.sensitivity_score
                    }
                  }
                }
              }

              dynamic "primitive_transformation" {
                for_each = [transformations.value.primitive_transformation]

                content {
                  dynamic "replace_config" {
                    for_each = (
                      primitive_transformation.value.replace_config == null
                      ? [] : [primitive_transformation.value.replace_config]
                    )

                    content {
                      dynamic "new_value" {
                        for_each = [replace_config.value.new_value]

                        content {
                          integer_value     = new_value.value.integer_value
                          float_value       = new_value.value.float_value
                          string_value      = new_value.value.string_value
                          boolean_value     = new_value.value.boolean_value
                          timestamp_value   = new_value.value.timestamp_value
                          day_of_week_value = new_value.value.day_of_week_value

                          dynamic "time_value" {
                            for_each = (
                              new_value.value.time_value == null
                              ? [] : [new_value.value.time_value]
                            )

                            content {
                              hours   = time_value.value.hours
                              minutes = time_value.value.minutes
                              seconds = time_value.value.seconds
                              nanos   = time_value.value.nanos
                            }
                          }

                          dynamic "date_value" {
                            for_each = (
                              new_value.value.date_value == null
                              ? [] : [new_value.value.date_value]
                            )

                            content {
                              day   = date_value.value.day
                              month = date_value.value.month
                              year  = date_value.value.year
                            }
                          }
                        }
                      }
                    }
                  }

                  dynamic "character_mask_config" {
                    for_each = (
                      primitive_transformation.value.character_mask_config == null
                      ? [] : [primitive_transformation.value.character_mask_config]
                    )

                    content {
                      masking_character = character_mask_config.value.masking_character
                      number_to_mask    = character_mask_config.value.number_to_mask
                      reverse_order     = character_mask_config.value.reverse_order

                      dynamic "characters_to_ignore" {
                        for_each = (
                          character_mask_config.value.characters_to_ignore == null
                          ? [] : [character_mask_config.value.characters_to_ignore]
                        )

                        content {
                          characters_to_skip          = characters_to_ignore.value.characters_to_skip
                          common_characters_to_ignore = characters_to_ignore.value.common_characters_to_ignore
                        }
                      }
                    }
                  }

                  dynamic "crypto_deterministic_config" {
                    for_each = (
                      primitive_transformation.value.crypto_deterministic_config == null
                      ? [] : [primitive_transformation.value.crypto_deterministic_config]
                    )

                    content {
                      dynamic "crypto_key" {
                        for_each = (
                          crypto_deterministic_config.value.crypto_key == null
                          ? [] : [crypto_deterministic_config.value.crypto_key]
                        )

                        content {
                          dynamic "transient" {
                            for_each = (
                              crypto_key.value.transient == null
                              ? [] : [crypto_key.value.transient]
                            )

                            content {
                              name = transient.value.name
                            }
                          }

                          dynamic "unwrapped" {
                            for_each = (
                              crypto_key.value.unwrapped == null
                              ? [] : [crypto_key.value.unwrapped]
                            )

                            content {
                              key = unwrapped.value.key
                            }
                          }

                          dynamic "kms_wrapped" {
                            for_each = (
                              crypto_key.value.kms_wrapped == null
                              ? [] : [crypto_key.value.kms_wrapped]
                            )

                            content {
                              wrapped_key     = kms_wrapped.value.wrapped_key
                              crypto_key_name = kms_wrapped.value.crypto_key_name
                            }
                          }
                        }
                      }

                      dynamic "surrogate_info_type" {
                        for_each = (
                          crypto_deterministic_config.value.surrogate_info_type == null
                          ? [] : [crypto_deterministic_config.value.surrogate_info_type]
                        )

                        content {
                          name    = surrogate_info_type.value.name
                          version = surrogate_info_type.value.version

                          dynamic "sensitivity_score" {
                            for_each = (
                              surrogate_info_type.value.sensitivity_score == null
                              ? {} : { 1 = 1 }
                            )

                            content {
                              score = surrogate_info_type.value.sensitivity_score
                            }
                          }
                        }
                      }

                      dynamic "context" {
                        for_each = (
                          crypto_deterministic_config.value.context == null
                          ? [] : [crypto_deterministic_config.value.context]
                        )

                        content {
                          name = context.value.name
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
