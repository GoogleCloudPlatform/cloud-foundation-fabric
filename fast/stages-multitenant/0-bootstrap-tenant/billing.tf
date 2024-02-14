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

# tfdoc:file:description Billing roles for standalone billing accounts.

locals {
  billing_mode = (
    var.billing_account.no_iam
    ? null
    : var.billing_account.is_org_level ? "org" : "resource"
  )
}

# service account billing roles are in the SA module in automation.tf

resource "google_billing_account_iam_member" "billing_ext_admin" {
  for_each = toset(
    local.billing_mode == "resource"
    ? [
      "group:${local.groups.gcp-admins}",
      module.automation-tf-resman-sa.iam_email
    ]
    : []
  )
  billing_account_id = var.billing_account.id
  role               = "roles/billing.admin"
  member             = each.key
}

resource "google_billing_account_iam_member" "billing_ext_cost_manager" {
  for_each = toset(
    local.billing_mode == "resource"
    ? [
      "group:${local.groups.gcp-admins}",
      module.automation-tf-resman-sa.iam_email
    ]
    : []
  )
  billing_account_id = var.billing_account.id
  role               = "roles/billing.costsManager"
  member             = each.key
}
