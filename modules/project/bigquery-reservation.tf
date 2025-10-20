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

locals {
  _assignments = flatten([
    for reservation_name, reservation in var.bigquery_reservations : [
      for job_type, assignees in reservation.assignments : [
        for assignee in assignees : {
          key              = "${reservation_name}-${job_type}-${assignee}"
          reservation_name = reservation_name
          location         = reservation.location
          job_type         = job_type
          assignee         = assignee
        }
      ]
    ]
  ])
  assignments = { for a in local._assignments : a.key => a }
}

resource "google_bigquery_reservation" "default" {
  for_each = var.bigquery_reservations

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
  for_each = local.assignments

  project     = local.project.project_id
  location    = each.value.location
  reservation = google_bigquery_reservation.default[each.value.reservation_name].id
  assignee    = each.value.assignee
  job_type    = each.value.job_type
}
