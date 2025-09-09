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
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  ctx_p = "$"
  iam_email = (
    local.service_account != null
    ? "serviceAccount:${local.service_account.email}"
    : local.static_iam_email
  )
  name       = split("@", var.name)[0]
  prefix     = var.prefix == null ? "" : "${var.prefix}-"
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  static_email = (
    "${local.prefix}${local.name}@${local.sa_domain}.iam.gserviceaccount.com"
  )
  static_iam_email = "serviceAccount:${local.static_email}"
  static_id = (
    "projects/${local.project_id}/serviceAccounts/${local.static_email}"
  )
  service_account = (
    var.service_account_create
    ? try(google_service_account.service_account[0], null)
    : try(data.google_service_account.service_account[0], null)
  )
  # universe-related locals
  universe               = try(regex("^([^:]*):[a-z]", local.project_id)[0], "")
  project_id_no_universe = element(split(":", local.project_id), 1)
  sa_domain = join(".", compact([
    local.project_id_no_universe, local.universe
  ]))
}

data "google_service_account" "service_account" {
  count      = var.service_account_create ? 0 : 1
  project    = local.project_id
  account_id = "${local.prefix}${local.name}"
}

resource "google_service_account" "service_account" {
  count                        = var.service_account_create ? 1 : 0
  project                      = local.project_id
  account_id                   = "${local.prefix}${local.name}"
  display_name                 = var.display_name
  description                  = var.description
  create_ignore_already_exists = var.create_ignore_already_exists
}

resource "google_tags_tag_binding" "binding" {
  for_each  = var.tag_bindings
  parent    = "//iam.googleapis.com/projects/${coalesce(var.project_number, var.project_id)}/serviceAccounts/${local.service_account.unique_id}"
  tag_value = lookup(local.ctx.tag_values, each.value, each.value)
}
