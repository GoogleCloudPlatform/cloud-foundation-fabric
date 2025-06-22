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


resource "google_clouddeploy_automation" "default" {
  for_each = local.validated_automations

  project           = coalesce(each.value.project_id, var.project_id)
  location          = coalesce(each.value.region, var.region)
  name              = each.key
  annotations       = each.value.annotations
  delivery_pipeline = google_clouddeploy_delivery_pipeline.default.name
  description       = each.value.description
  labels            = each.value.labels
  service_account   = coalesce(each.value.service_account, local.compute_default_service_account)
  suspended         = each.value.suspended

  dynamic "rules" {
    for_each = each.value.advance_rollout_rule == null ? [] : [""]

    content {
      dynamic "advance_rollout_rule" {
        for_each = each.value.advance_rollout_rule == null ? [] : [""]

        content {
          id            = each.value.advance_rollout_rule.id
          source_phases = each.value.advance_rollout_rule.source_phases
          wait          = each.value.advance_rollout_rule.wait
        }
      }
    }
  }

  dynamic "rules" {
    for_each = each.value.promote_release_rule == null ? [] : [""]

    content {
      dynamic "promote_release_rule" {
        for_each = each.value.promote_release_rule == null ? [] : [""]

        content {
          id                    = each.value.promote_release_rule.id
          destination_phase     = each.value.promote_release_rule.destination_target_id
          destination_target_id = each.value.promote_release_rule.destination_target_id
          wait                  = each.value.promote_release_rule.wait
        }
      }
    }
  }

  dynamic "rules" {
    for_each = each.value.repair_rollout_rule == null ? [] : [""]

    content {
      dynamic "repair_rollout_rule" {
        for_each = each.value.repair_rollout_rule == null ? [] : [""]

        content {
          id     = each.value.repair_rollout_rule.id
          jobs   = each.value.repair_rollout_rule.jobs
          phases = each.value.repair_rollout_rule.phases

          dynamic "repair_phases" {
            for_each = each.value.repair_rollout_rule.retry == null ? [] : [""]

            content {
              retry {
                attempts     = each.value.repair_rollout_rule.retry.attempts
                backoff_mode = each.value.repair_rollout_rule.retry.backoff_mode
                wait         = each.value.repair_rollout_rule.retry.wait
              }
            }
          }
          dynamic "repair_phases" {
            for_each = each.value.repair_rollout_rule.rollback == null ? [] : [""]

            content {
              rollback {
                destination_phase                   = each.value.repair_rollout_rule.rollback.destination_phase
                disable_rollback_if_rollout_pending = each.value.repair_rollout_rule.rollback.disable_rollback_if_rollout_pending
              }
            }
          }
        }
      }
    }
  }

  dynamic "rules" {
    for_each = each.value.timed_promote_release_rule == null ? [] : [""]

    content {
      dynamic "timed_promote_release_rule" {
        for_each = each.value.timed_promote_release_rule == null ? [] : [""]

        content {
          id                    = each.value.timed_promote_release_rule.id
          destination_phase     = each.value.timed_promote_release_rule.destination_phase
          destination_target_id = each.value.timed_promote_release_rule.destination_target_id
          schedule              = each.value.timed_promote_release_rule.schedule
          time_zone             = each.value.timed_promote_release_rule.time_zone
        }
      }
    }
  }

  selector {
    dynamic "targets" {
      for_each = {
        for k, v in each.value.selector :
        k => v
      }
      iterator = et

      content {
        id     = et.value.id
        labels = et.value.labels
      }
    }
  }
}