/**
 * Copyright 2021 Google LLC
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

resource "google_cloud_identity_group" "iap_support_group" {
  provider = google-beta

  display_name = format("IAP support: %s", title(var.project_id))

  parent = format("customers/%s", var.customer_id)

  group_key {
    id = replace(replace(var.email_format, "%domain%", var.domain), "%project%", var.project_id)
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

resource "google_cloud_identity_group_membership" "iap_support_group_membership" {
  provider = google-beta

  group = google_cloud_identity_group.iap_support_group.id

  member_key {
    id = var.service_account
  }

  roles {
    name = "MANAGER"
  }

  roles {
    name = "MEMBER"
  }

  lifecycle {
    ignore_changes = [
      roles,
    ]
  }
}

resource "google_iap_brand" "project_brand" {
  for_each = var.title != "" ? var.project_ids_full : {}

  support_email     = google_cloud_identity_group.iap_support_group.group_key[0].id
  application_title = var.title
  project           = each.value

  depends_on = [
    google_cloud_identity_group_membership.iap_support_group_membership
  ]
}
