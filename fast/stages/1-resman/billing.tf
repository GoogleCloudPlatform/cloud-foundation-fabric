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

# tfdoc:file:description Billing resources for external billing use cases.

locals {
  # used here for convenience, in organization.tf members are explicit
  billing_ext_users = concat(
    [
      module.branch-network-sa.iam_email,
      module.branch-security-sa.iam_email,
    ],
    local.branch_optional_sa_lists.dp-dev,
    local.branch_optional_sa_lists.dp-prod,
    local.branch_optional_sa_lists.gke-dev,
    local.branch_optional_sa_lists.gke-prod,
    local.branch_optional_sa_lists.pf-dev,
    local.branch_optional_sa_lists.pf-prod,
  )
  billing_mode = (
    var.billing_account.no_iam
    ? null
    : var.billing_account.is_org_level ? "org" : "resource"
  )
}

# billing account in same org (resources is in the organization.tf file)

# standalone billing account

resource "google_billing_account_iam_member" "billing_ext_admin" {
  for_each = toset(
    local.billing_mode == "resource" ? local.billing_ext_users : []
  )
  billing_account_id = var.billing_account.id
  role               = "roles/billing.user"
  member             = each.key
}

resource "google_billing_account_iam_member" "billing_ext_costsmanager" {
  for_each = toset(
    local.billing_mode == "resource" ? local.billing_ext_users : []
  )
  billing_account_id = var.billing_account.id
  role               = "roles/billing.costsManager"
  member             = each.key
}
