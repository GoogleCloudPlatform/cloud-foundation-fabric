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
  ischedule = try(var.instance_schedule.create_config, null)
  ischedule_attach = var.instance_schedule == null ? null : (
    var.instance_schedule.create_config != null
    # created policy with optional attach to allow policy destroy
    ? (
      var.instance_schedule.create_config.active
      ? [google_compute_resource_policy.schedule[0].id]
      : null
    )
    # externally managed policy
    : [var.instance_schedule.resource_policy_id]
  )
}

resource "google_compute_resource_policy" "schedule" {
  count   = local.ischedule != null ? 1 : 0
  project = var.project_id
  region  = substr(var.zone, 0, length(var.zone) - 2)
  name    = var.name
  description = coalesce(
    local.ischedule.description, "Schedule policy for ${var.name}."
  )
  instance_schedule_policy {
    expiration_time = local.ischedule.expiration_time
    start_time      = local.ischedule.start_time
    time_zone       = local.ischedule.timezone
    dynamic "vm_start_schedule" {
      for_each = local.ischedule.vm_start != null ? [""] : []
      content {
        schedule = local.ischedule.vm_start
      }
    }
    dynamic "vm_stop_schedule" {
      for_each = local.ischedule.vm_stop != null ? [""] : []
      content {
        schedule = local.ischedule.vm_stop
      }
    }
  }
}

resource "google_compute_resource_policy" "snapshot" {
  for_each = var.snapshot_schedules
  project  = var.project_id
  region   = substr(var.zone, 0, length(var.zone) - 2)
  name     = "${var.name}-${each.key}"
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
      for_each = each.value.retention_policy != null ? [""] : []
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
      for_each = each.value.snapshot_properties != null ? [""] : []
      content {
        labels            = each.value.snapshot_properties.labels
        storage_locations = each.value.snapshot_properties.storage_locations
        guest_flush       = each.value.snapshot_properties.guest_flush
      }
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "boot" {
  count   = var.boot_disk.snapshot_schedule != null ? 1 : 0
  project = var.project_id
  zone    = var.zone
  name = try(
    google_compute_resource_policy.snapshot[var.boot_disk.snapshot_schedule].name,
    var.boot_disk.snapshot_schedule
  )
  disk       = var.name
  depends_on = [google_compute_instance.default]
}

resource "google_compute_disk_resource_policy_attachment" "attached" {
  for_each = {
    for k, v in local.attached_disks_zonal :
    k => v if v.snapshot_schedule != null
  }
  project = var.project_id
  zone    = var.zone
  name = try(
    google_compute_resource_policy.snapshot[each.value.snapshot_schedule].name,
    each.value.snapshot_schedule
  )
  disk = (
    each.value.source_type == "attach"
    ? each.value.source
    : google_compute_disk.disks[each.key].name
  )
  depends_on = [
    google_compute_instance.default,
    google_compute_disk.disks
  ]
}

resource "google_compute_region_disk_resource_policy_attachment" "attached" {
  for_each = {
    for k, v in local.attached_disks_regional :
    k => v if v.snapshot_schedule != null
  }
  project = var.project_id
  region  = substr(var.zone, 0, length(var.zone) - 2)
  name = try(
    google_compute_resource_policy.snapshot[each.value.snapshot_schedule].name,
    each.value.snapshot_schedule
  )
  disk = (
    each.value.source_type == "attach"
    ? each.value.source
    : google_compute_region_disk.disks[each.key].name
  )
  depends_on = [
    google_compute_instance.default,
    google_compute_region_disk.disks
  ]
}
