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

  project     = coalesce(each.value.project_id, var.project_id)
  location    = coalesce(each.value.region, var.region)
  name        = each.key
  annotations = each.value.annotations
  description = each.value.description
  labels      = each.value.labels
  suspended   = each.value.suspended

  dynamic "rules" {
    for_each = each.value.rollout_restrictions
    iterator = er

    content {
      rollout_restriction {
        id       = er.key
        actions  = er.value.actions
        invokers = er.value.invokers

        time_windows {
          time_zone = er.value.time_zone

          dynamic "one_time_windows" {
            for_each = {
              for k, v in er.value.one_time_windows :
              k => v
            }
            iterator = eotw

            content {
              dynamic "end_date" {
                for_each = eotw.value.end_date == null ? [] : [""]

                content {
                  day   = eotw.value.end_date.day
                  month = eotw.value.end_date.month
                  year  = eotw.value.end_date.year
                }
              }

              dynamic "end_time" {
                for_each = eotw.value.end_time == null ? [] : [""]

                content {
                  hours   = eotw.value.end_time.hours
                  minutes = eotw.value.end_time.minutes
                  seconds = eotw.value.end_time.seconds
                  nanos   = eotw.value.end_time.nanos
                }
              }

              dynamic "start_date" {
                for_each = eotw.value.start_date == null ? [] : [""]

                content {
                  day   = eotw.value.start_date.day
                  month = eotw.value.start_date.month
                  year  = eotw.value.start_date.year
                }
              }

              dynamic "start_time" {
                for_each = eotw.value.start_time == null ? [] : [""]

                content {
                  hours   = eotw.value.start_time.hours
                  minutes = eotw.value.start_time.minutes
                  seconds = eotw.value.start_time.seconds
                  nanos   = eotw.value.start_time.nanos
                }
              }
            }
          }

          dynamic "weekly_windows" {
            for_each = {
              for k, v in er.value.weekly_windows :
              k => v
            }
            iterator = eww

            content {
              days_of_week = eww.value.days_of_week

              dynamic "end_time" {
                for_each = eww.value.end_time == null ? [] : [""]

                content {
                  hours   = eww.value.end_time.hours
                  minutes = eww.value.end_time.minutes
                  seconds = eww.value.end_time.seconds
                  nanos   = eww.value.end_time.nanos
                }
              }

              dynamic "start_time" {
                for_each = eww.value.start_time == null ? [] : [""]

                content {
                  hours   = eww.value.start_time.hours
                  minutes = eww.value.start_time.minutes
                  seconds = eww.value.start_time.seconds
                  nanos   = eww.value.start_time.nanos
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "selectors" {
    for_each = {
      for k, v in each.value.selectors :
      k => v
    }
    iterator = es

    content {
      dynamic "delivery_pipeline" {
        for_each = upper(es.value.type) == "DELIVERY_PIPELINE" ? [""] : []

        content {
          id     = es.value.id
          labels = es.value.labels
        }
      }

      dynamic "target" {
        for_each = upper(es.value.type) == "TARGET" ? [""] : []

        content {
          id     = es.value.id
          labels = es.value.labels
        }
      }
    }
  }
}