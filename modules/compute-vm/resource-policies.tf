/**
 * Copyright 2023 Google LLC
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

# tfdoc:file:description Resource policies.

locals {
  schedule_p = try(var.instance_schedule.create_config, null)
}

resource "google_compute_resource_policy" "schedule" {
  count  = local.schedule_p != null ? 1 : 0
  name   = var.name
  region = substr(var.zone, 0, length(var.zone) - 2)
  description = coalesce(
    local.schedule_p.description, "Schedule policy for ${var.name}."
  )
  instance_schedule_policy {
    expiration_time = local.schedule_p.expiration_time
    start_time      = local.schedule_p.start_time
    time_zone       = local.schedule_p.timezone
    dynamic "vm_start_schedule" {
      for_each = local.schedule_p.vm_start != null ? [""] : []
      content {
        schedule = local.schedule_p.vm_start
      }
    }
    dynamic "vm_stop_schedule" {
      for_each = local.schedule_p.vm_stop != null ? [""] : []
      content {
        schedule = local.schedule_p.vm_stop
      }
    }
  }
}

resource "google_compute_resource_policy" "snapshot" {
  for_each = var.snapshot_schedules
  name     = "${var.name}-${each.key}"
  region   = substr(var.zone, 0, length(var.zone) - 2)
  description = coalesce(
    each.value.description, "Schedule policy ${each.key} for ${var.name}."
  )
  snapshot_schedule_policy {
    schedule {
      dynamic "daily_schedule" {
        for_each = each.value.schedule.daily != null ? [""] : []
        content {
          days_in_cycle = each.value.schedule.daily.days_in_cycle
          start_time    = each.value.schedule.daily.start_time
        }
      }
      dynamic "hourly_schedule" {
        for_each = each.value.schedule.hourly != null ? [""] : []
        content {
          hours_in_cycle = each.value.schedule.hourly.hours_in_cycle
          start_time     = each.value.schedule.hourly.start_time
        }
      }
      dynamic "weekly_schedule" {
        for_each = each.value.schedule.weekly != null ? [""] : []
        content {
          dynamic "day_of_weeks" {
            for_each = each.value.schedule.weekly
            content {
              day        = day_of_weeks.value.day
              start_time = day_of_weeks.value.start_time
            }
          }
        }
      }
    }
    dynamic "retention_policy" {
      for_each = each.value.retention_policy != null ? [] : [""]
      content {
        max_retention_days = each.value.retention_policy.max_retention_days
        on_source_disk_delete = (
          each.value.retention_policy.on_source_disk_delete_keep == false
          ? "APPLY_RETENTION_POLICY"
          : "KEEP_AUTO_SNAPSHOTS"
        )
      }
    }
    dynamic "snapshot_properties" {
      for_each = each.value.snapshot_properties != null ? [] : [""]
      content {
        labels            = each.value.snapshot_properties.labels
        storage_locations = each.value.snapshot_properties.storage_locations
        guest_flush       = each.value.snapshot_properties.guest_flush
      }
    }
  }
}
