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


resource "google_clouddeploy_deploy_policy" "default" {
  for_each = var.deploy_policies

  name        = each.key
  project     = coalesce(each.value.project_id, var.project_id)
  location    = coalesce(each.value.region, var.region)
  annotations = each.value.annotations
  labels      = each.value.labels
  description = each.value.description

  dynamic "selectors" {
    for_each = {
      for k, v in each.value.selectors :
      k => v
    }
    iterator = each_selector

    content {
      dynamic "delivery_pipeline" {
        for_each = upper(each_selector.value.type) == "DELIVERY_PIPELINE" ? [""] : []

        content {
          id     = each_selector.value.id
          labels = each_selector.value.labels
        }
      }

      dynamic "target" {
        for_each = upper(each_selector.value.type) == "TARGET" ? [""] : []

        content {
          id     = each_selector.value.id
          labels = each_selector.value.labels
        }
      }
    }
  }

  suspended = each.value.suspended


  dynamic "rules" {
    for_each = each.value.rollout_restrictions
    iterator = each_rule

    content {
      rollout_restriction {
        id       = each_rule.key
        invokers = each_rule.value.invokers
        actions  = each_rule.value.actions
        time_windows {
          time_zone = each_rule.value.time_zone

          dynamic "weekly_windows" {
            for_each = {
              for k, v in each_rule.value.weekly_windows :
              k => v
            }
            iterator = each_weekly_window

            content {

              dynamic "start_time" {
                for_each = each_weekly_window.value.start_time == null ? [] : [""]

                content {
                  hours   = each_weekly_window.value.start_time.hours
                  minutes = each_weekly_window.value.start_time.minutes
                  seconds = each_weekly_window.value.start_time.seconds
                  nanos   = each_weekly_window.value.start_time.nanos
                }
              }

              dynamic "end_time" {
                for_each = each_weekly_window.value.end_time == null ? [] : [""]

                content {
                  hours   = each_weekly_window.value.end_time.hours
                  minutes = each_weekly_window.value.end_time.minutes
                  seconds = each_weekly_window.value.end_time.seconds
                  nanos   = each_weekly_window.value.end_time.nanos
                }
              }

              days_of_week = each_weekly_window.value.days_of_week
            }

          }

          dynamic "one_time_windows" {
            for_each = {
              for k, v in each_rule.value.one_time_windows :
              k => v
            }
            iterator = each_one_time_window

            content {
              dynamic "start_time" {
                for_each = each_one_time_window.value.start_time == null ? [] : [""]

                content {
                  hours   = each_one_time_window.value.start_time.hours
                  minutes = each_one_time_window.value.start_time.minutes
                  seconds = each_one_time_window.value.start_time.seconds
                  nanos   = each_one_time_window.value.start_time.nanos
                }
              }

              dynamic "end_time" {
                for_each = each_one_time_window.value.end_time == null ? [] : [""]

                content {
                  hours   = each_one_time_window.value.end_time.hours
                  minutes = each_one_time_window.value.end_time.minutes
                  seconds = each_one_time_window.value.end_time.seconds
                  nanos   = each_one_time_window.value.end_time.nanos
                }
              }

              dynamic "start_date" {
                for_each = each_one_time_window.value.start_date == null ? [] : [""]

                content {
                  year  = each_one_time_window.value.start_date.year
                  month = each_one_time_window.value.start_date.month
                  day   = each_one_time_window.value.start_date.day

                }
              }

              dynamic "end_date" {
                for_each = each_one_time_window.value.end_date == null ? [] : [""]

                content {
                  year  = each_one_time_window.value.end_date.year
                  month = each_one_time_window.value.end_date.month
                  day   = each_one_time_window.value.end_date.day
                }
              }
            }
          }
        }
      }
    }
  }
}