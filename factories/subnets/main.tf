/**
 * Copyright 2022 Google LLC
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
  _data = {
    for f in fileset(var.config_folder, "**/*.yaml") :
    trimsuffix(split("/", f)[2], ".yaml") => merge(
      yamldecode(file("${var.config_folder}/${f}")),
      {
        project_id = split("/", f)[0]
        network    = split("/", f)[1]
      }
    )
  }

  data = {
    for k, v in local._data : k => merge(v,
      {
        network_users : concat(
          formatlist("group:%s", try(v.iam_groups, [])),
          formatlist("user:%s", try(v.iam_users, [])),
          formatlist("serviceAccount:%s", try(v.iam_service_accounts, []))
        )
      }
    )
  }
}

resource "google_compute_subnetwork" "default" {
  for_each                 = local.data
  project                  = each.value.project_id
  network                  = each.value.network
  name                     = each.key
  region                   = each.value.region
  description              = each.value.description
  ip_cidr_range            = each.value.ip_cidr_range
  private_ip_google_access = try(each.value.private_ip_google_access, true)

  dynamic "secondary_ip_range" {
    for_each = try(each.value.secondary_ip_ranges, [])
    iterator = secondary_range
    content {
      range_name    = secondary_range.key
      ip_cidr_range = secondary_range.value
    }
  }
}


resource "google_compute_subnetwork_iam_binding" "default" {
  for_each = {
    for k, v in local.data : k => v if length(v.network_users) > 0
  }
  project    = each.value.project_id
  subnetwork = google_compute_subnetwork.default[each.key].name
  region     = each.value.region
  role       = "roles/compute.networkUser"
  members    = each.value.network_users
}
