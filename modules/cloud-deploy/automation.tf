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


resource "google_clouddeploy_automation" "automation" {
  for_each = {
    for key, each_automation in var.automations :
    key => each_automation if length(each_automation.promote_release_rule) > 0 || length(each_automation.advance_rollout_rule) > 0 || length(each_automation.repair_rollout_rule) > 0 || length(each_automation.timed_promote_release_rule) > 0
  }

  name              = each.key
  project           = coalesce(each.value.project_id, var.project_id)
  location          = coalesce(each.value.region, var.region)
  delivery_pipeline = google_clouddeploy_delivery_pipeline.pipeline.name
  service_account   = coalesce(each.value.service_account, local.compute_default_service_account)
  annotations       = each.value.annotations
  labels            = each.value.labels
  description       = each.value.description
  selector {
    dynamic "targets" {
      for_each = {
        for index, each_target in each.value.selector :
        index => each_target
      }
      iterator = each_target

      content {
        id     = each_target.value.id
        labels = each_target.value.labels
      }
    }
  }

  suspended = each.value.suspended

  dynamic "rules" {
    for_each = each.value.promote_release_rule == null ? [] : [""]

    content {
      dynamic "promote_release_rule" {
        for_each = each.value.promote_release_rule == null ? [] : [""]

        content {
          id                    = each.value.promote_release_rule.id
          wait                  = each.value.promote_release_rule.wait
          destination_target_id = each.value.promote_release_rule.destination_target_id
          destination_phase     = each.value.promote_release_rule.destination_target_id
        }
      }
    }
  }

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
    for_each = each.value.repair_rollout_rule == null ? [] : [""]

    content {

      dynamic "repair_rollout_rule" {
        for_each = each.value.repair_rollout_rule == null ? [] : [""]

        content {
          id     = each.value.repair_rollout_rule.id
          phases = each.value.repair_rollout_rule.phases
          jobs   = each.value.repair_rollout_rule.jobs

          dynamic "repair_phases" {
            for_each = each.value.repair_rollout_rule.retry == null ? [] : [""]

            content {
              retry {
                attempts     = each.value.repair_rollout_rule.retry.attempts
                wait         = each.value.repair_rollout_rule.retry.wait
                backoff_mode = each.value.repair_rollout_rule.retry.backoff_mode
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
          destination_target_id = each.value.timed_promote_release_rule.destination_target_id
          schedule              = each.value.timed_promote_release_rule.schedule
          time_zone             = each.value.timed_promote_release_rule.time_zone
          destination_phase     = each.value.timed_promote_release_rule.destination_phase
        }
      }
    }
  }
}