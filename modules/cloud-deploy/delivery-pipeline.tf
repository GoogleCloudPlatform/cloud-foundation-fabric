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
        iterator = et

        content {
          profiles  = et.value.profiles
          target_id = et.value.name

          dynamic "deploy_parameters" {
            for_each = {
              for k, v in et.value.delivery_pipeline_deploy_parameters :
              k => v
            }
            iterator = edp

            content {
              match_target_labels = edp.value.matching_target_labels
              values              = edp.value.values
            }
          }

          dynamic "strategy" {
            for_each = et.value.strategy == null ? [] : [""]

            content {
              dynamic "canary" {
                for_each = upper(et.value.strategy) == "CANARY" ? [""] : []

                content {
                  canary_deployment {
                    percentages = et.value.deployment_percentages
                    verify      = et.value.verify

                    dynamic "postdeploy" {
                      for_each = et.value.postdeploy_actions == null ? [] : [""]
                      content {
                        actions = et.value.postdeploy_actions
                      }
                    }

                    dynamic "predeploy" {
                      for_each = et.value.predeploy_actions == null ? [] : [""]
                      content {
                        actions = et.value.predeploy_actions
                      }
                    }
                  }

                  dynamic "custom_canary_deployment" {
                    for_each = length(et.value.custom_canary_phase_configs) > 0 ? [""] : []

                    content {
                      dynamic "phase_configs" {
                        for_each = et.value.custom_canary_phase_configs
                        iterator = epc

                        content {
                          percentage = epc.value.percentage
                          phase_id   = epc.key
                          verify     = epc.value.verify

                          dynamic "postdeploy" {
                            for_each = epc.value.postdeploy_actions == null ? [] : [""]

                            content {
                              actions = epc.value.postdeploy_actions
                            }
                          }

                          dynamic "predeploy" {
                            for_each = epc.value.predeploy_actions == null ? [] : [""]

                            content {
                              actions = epc.value.predeploy_actions
                            }
                          }
                        }
                      }
                    }
                  }

                  runtime_config {
                    dynamic "cloud_run" {
                      for_each = et.value.cloud_run_configs == null ? [] : [""]

                      content {
                        automatic_traffic_control = et.value.cloud_run_configs.automatic_traffic_control
                        canary_revision_tags      = et.value.cloud_run_configs.canary_revision_tags
                        prior_revision_tags       = et.value.cloud_run_configs.prior_revision_tags
                        stable_revision_tags      = et.value.cloud_run_configs.stable_revision_tags
                      }
                    }
                  }
                }
              }

              dynamic "standard" {
                for_each = upper(et.value.strategy) == "STANDARD" ? [""] : []

                content {
                  verify = et.value.verify

                  dynamic "postdeploy" {
                    for_each = et.value.postdeploy_actions == null ? [] : [""]
                    content {
                      actions = et.value.postdeploy_actions
                    }
                  }

                  dynamic "predeploy" {
                    for_each = et.value.predeploy_actions == null ? [] : [""]
                    content {
                      actions = et.value.predeploy_actions
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

