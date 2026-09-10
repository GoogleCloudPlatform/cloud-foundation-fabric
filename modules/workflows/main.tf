# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  _ctx_p = "$"
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local._ctx_p}${k}:${kk}" => vv
    } if !endswith(k, "_vars")
  }
  crypto_key_name = (
    var.crypto_key_name == null
    ? null
    : lookup(local.ctx.crypto_keys, var.crypto_key_name, var.crypto_key_name)
  )
  prefix     = var.prefix == null ? "" : "${var.prefix}-"
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  region     = lookup(local.ctx.locations, var.region, var.region)
  service_account = (
    var.service_account_create
    ? google_service_account.service_account[0].email
    : (
      var.service_account == null
      ? null
      : lookup(
        local.ctx.service_accounts,
        var.service_account,
        var.service_account
      )
    )
  )
}

resource "google_service_account" "service_account" {
  count      = var.service_account_create ? 1 : 0
  provider   = google
  project    = local.project_id
  account_id = "${local.prefix}${var.name}"
  display_name = (
    "Workflows execution service account for ${local.prefix}${var.name}."
  )
}

resource "google_project_iam_member" "service_account" {
  for_each = (
    var.service_account_create ? toset(var.service_account_roles) : toset([])
  )
  provider = google
  project  = local.project_id
  role     = each.value
  member = (
    "serviceAccount:${google_service_account.service_account[0].email}"
  )
}

resource "google_workflows_workflow" "default" {
  provider                = google
  project                 = local.project_id
  name                    = "${local.prefix}${var.name}"
  region                  = local.region
  description             = var.description
  labels                  = var.labels
  service_account         = local.service_account
  source_contents         = var.source_contents
  call_log_level          = var.call_log_level
  execution_history_level = var.execution_history_level
  crypto_key_name         = local.crypto_key_name
  user_env_vars           = var.user_env_vars
  deletion_protection     = var.deletion_protection
}
