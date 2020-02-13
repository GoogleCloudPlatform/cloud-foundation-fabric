/**
 * Copyright 2019 Google LLC
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
  iam_billing_pairs = {
    for pair in setproduct(var.billing_roles, var.administrators) :
    join("-", pair) => { role = pair.0, member = pair.1 }
  }
  iam_organization_pairs = {
    for pair in setproduct(var.organization_roles, var.administrators) :
    join("-", pair) => { role = pair.0, member = pair.1 }
  }
}

resource "google_folder" "folder" {
  provider     = google-beta
  display_name = var.name
  parent       = var.parent
}

resource "google_folder_iam_binding" "authoritative" {
  for_each = toset(var.folder_roles)
  provider = google-beta
  folder   = google_folder.folder.name
  role     = each.value
  members  = var.administrators
}

resource "google_billing_account_iam_member" "non_authoritative" {
  for_each           = local.iam_billing_pairs
  billing_account_id = var.billing_account
  role               = each.value.role
  member             = each.value.member
}

resource "google_organization_iam_member" "non_authoritative" {
  for_each = local.iam_organization_pairs
  org_id   = var.organization_id
  role     = each.value.role
  member   = each.value.member
}
