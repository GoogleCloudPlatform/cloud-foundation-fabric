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
    local.schedule_p.description, "Schedule policy for ${var.name}"
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
