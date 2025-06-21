/**
 * Copyright 2025 Google LLC
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


resource "google_clouddeploy_delivery_pipeline" "default" {
  project     = var.project_id
  location    = var.region
  name        = var.name
  annotations = var.annotations
  description = var.description
  labels      = var.labels
  suspended   = var.suspended
  dynamic "serial_pipeline" {
    for_each = lower(local.pipeline_type) == "serial" ? [""] : []
    content {
      dynamic "stages" {
        for_each = {
          for k, v in var.targets :
          k => v if v.exclude_from_pipeline == false
        }
        iterator = each_target
        content {
          dynamic "deploy_parameters" {
            for_each = {
              for k, v in each_target.value.delivery_pipeline_deploy_parameters :
              k => v
            }
            iterator = each_deploy_parameter
            content {
              values              = each_deploy_parameter.value.values
              match_target_labels = each_deploy_parameter.value.matching_target_labels
            }
          }
          profiles = each_target.value.profiles
          dynamic "strategy" {
            for_each = each_target.value.strategy == null ? [] : [""]
            content {
              dynamic "standard" {
                for_each = upper(each_target.value.strategy) == "STANDARD" ? [""] : []
                content {
                  verify = each_target.value.verify
                  dynamic "predeploy" {
                    for_each = each_target.value.predeploy_actions == null ? [] : [""]
                    content {
                      actions = each_target.value.predeploy_actions
                    }
                  }
                  dynamic "postdeploy" {
                    for_each = each_target.value.postdeploy_actions == null ? [] : [""]
                    content {
                      actions = each_target.value.postdeploy_actions
                    }
                  }
                }
              }
              dynamic "canary" {
                for_each = upper(each_target.value.strategy) == "CANARY" ? [""] : []
                content {
                  canary_deployment {
                    percentages = each_target.value.deployment_percentages
                    verify      = each_target.value.verify
                    dynamic "predeploy" {
                      for_each = each_target.value.predeploy_actions == null ? [] : [""]
                      content {
                        actions = each_target.value.predeploy_actions
                      }
                    }
                    dynamic "postdeploy" {
                      for_each = each_target.value.postdeploy_actions == null ? [] : [""]
                      content {
                        actions = each_target.value.postdeploy_actions
                      }
                    }
                  }
                  dynamic "custom_canary_deployment" {
                    for_each = (
                      each_target.value.custom_canary_phase_configs != null &&
                      length(each_target.value.custom_canary_phase_configs) > 0
                      ? [""]
                      : []
                    )
                    content {
                      dynamic "phase_configs" {
                        for_each = each_target.value.custom_canary_phase_configs
                        iterator = each_phase_config
                        content {
                          phase_id   = each_phase_config.key
                          percentage = each_phase_config.value.percentage
                          verify     = each_phase_config.value.verify
                          dynamic "predeploy" {
                            for_each = each_phase_config.value.predeploy_actions == null ? [] : [""]
                            content {
                              actions = each_phase_config.value.predeploy_actions
                            }
                          }
                          dynamic "postdeploy" {
                            for_each = each_phase_config.value.postdeploy_actions == null ? [] : [""]
                            content {
                              actions = each_phase_config.value.postdeploy_actions
                            }
                          }
                        }
                      }
                    }
                  }
                  runtime_config {
                    dynamic "cloud_run" {
                      for_each = each_target.value.cloud_run_configs == null ? [] : [""]
                      content {
                        automatic_traffic_control = (
                          each_target.value.cloud_run_configs.automatic_traffic_control
                        )
                        canary_revision_tags = (
                          each_target.value.cloud_run_configs.canary_revision_tags
                        )
                        prior_revision_tags = (
                          each_target.value.cloud_run_configs.prior_revision_tags
                        )
                        stable_revision_tags = (
                          each_target.value.cloud_run_configs.stable_revision_tags
                        )
                      }
                    }

                  }
                }
              }
            }
          }
          target_id = each_target.value.name
        }
      }
    }
  }
}

