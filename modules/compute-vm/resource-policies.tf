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
  ischedule = var.instance_schedule == null ? null : [
    google_compute_resource_policy.schedule[0].id
  ]
  disk_zonal_schedule_attachments = flatten([
    for disk_key, disk_data in try(local.attached_disks_zonal, []) :
    disk_data.snapshot_schedule != null ? [
      for schedule in disk_data.snapshot_schedule : {
        disk_key          = disk_key
        source_type       = disk_data.source_type
        source            = disk_data.source
        snapshot_schedule = schedule
      }
    ] : []
  ])
  disk_regional_schedule_attachments = flatten([
    for disk_key, disk_data in try(local.attached_disks_regional, []) :
    disk_data.snapshot_schedule != null ? [
      for schedule in disk_data.snapshot_schedule : {
        disk_key          = disk_key
        source_type       = disk_data.source_type
        source            = disk_data.source
        snapshot_schedule = schedule
      }
    ] : []
  ])
}

resource "google_compute_resource_policy" "schedule" {
  count   = var.instance_schedule != null ? 1 : 0
  project = var.project_id
  region  = substr(var.zone, 0, length(var.zone) - 2)
  name    = var.name
  description = coalesce(
    var.instance_schedule.description, "Schedule policy for ${var.name}."
  )
  instance_schedule_policy {
    expiration_time = var.instance_schedule.expiration_time
    start_time      = var.instance_schedule.start_time
    time_zone       = var.instance_schedule.timezone
    dynamic "vm_start_schedule" {
      for_each = var.instance_schedule.vm_start != null ? [""] : []
      content {
        schedule = var.instance_schedule.vm_start
      }
    }
    dynamic "vm_stop_schedule" {
      for_each = var.instance_schedule.vm_stop != null ? [""] : []
      content {
        schedule = var.instance_schedule.vm_stop
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
  for_each = var.boot_disk.snapshot_schedule != null ? toset(var.boot_disk.snapshot_schedule) : []
  project  = var.project_id
  zone     = var.zone
  name = try(
    google_compute_resource_policy.snapshot[each.value].name,
    each.value
  )
  # if independent disk is used for boot disk it will have a different name compared to when created implicitly
  disk = (
    !local.template_create && var.boot_disk.use_independent_disk
    ? google_compute_disk.boot[0].name
    : var.name
  )
  depends_on = [google_compute_instance.default]
}

resource "google_compute_disk_resource_policy_attachment" "attached" {
  for_each = {
    for attachment in local.disk_zonal_schedule_attachments :
    "${attachment.disk_key}-${attachment.snapshot_schedule}" => attachment
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
    : google_compute_disk.disks[each.value.disk_key].name
  )
  depends_on = [
    google_compute_instance.default,
    google_compute_disk.disks
  ]
}

resource "google_compute_region_disk_resource_policy_attachment" "attached" {
  for_each = {
    for attachment in local.disk_regional_schedule_attachments :
    "${attachment.disk_key}-${attachment.snapshot_schedule}" => attachment
  }

  project = var.project_id
  name = try(
    google_compute_resource_policy.snapshot[each.value.snapshot_schedule].name,
    each.value.snapshot_schedule
  )
  disk = (
    each.value.source_type == "attach"
    ? each.value.source
    : google_compute_disk.disks[each.value.disk_key].name
  )
  depends_on = [
    google_compute_instance.default,
    google_compute_disk.disks
  ]
}
