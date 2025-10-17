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

resource "google_bigquery_reservation" "default" {
  for_each = var.bigquery_reservations.reservations

  project            = local.project.project_id
  location           = each.value.location
  name               = each.key
  slot_capacity      = each.value.slot_capacity
  ignore_idle_slots  = each.value.ignore_idle_slots
  concurrency        = each.value.concurrency
  edition            = each.value.edition
  secondary_location = each.value.secondary_location


  dynamic "autoscale" {
    for_each = each.value.max_slots == null ? [] : [each.value.max_slots]
    content {
      max_slots = autoscale.value
    }
  }

  depends_on = [
    google_project_service.project_services
  ]
}

resource "google_bigquery_reservation_assignment" "default" {
  for_each = var.bigquery_reservations.assign_to_reservation

  project     = each.value.project_id
  location    = each.value.location
  reservation = each.value.reservation
  assignee    = "projects/${local.project.project_id}"
  job_type    = each.key
}
