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
  service_account_email = (
    var.service_account_config.create
    ? try(google_service_account.service_account[0].email, null) # use managed SA, when creating
    : (var.service_account_config.email == null ? null           # set to null, if no email provided
      : lookup(                                                  # lookup SA in context
        local.ctx.iam_principals,
        var.service_account_config.email,
        var.service_account_config.email
      )
    )
  )
  roles = [
    for role in var.service_account_config.roles
    : lookup(local.ctx.custom_roles, role, role)
  ]
}

resource "google_service_account" "service_account" {
  count = (
    var.service_account_config.create
    && var.agent_engine_config.identity_type == "SERVICE_ACCOUNT"
    ? 1 : 0
  )
  project    = local.project_id
  account_id = coalesce(var.service_account_config.name, var.name)
  display_name = coalesce(
    var.service_account_config.display_name,
    var.service_account_config.name,
    var.name
  )
}

resource "google_project_iam_member" "default" {
  for_each = (
    var.service_account_config.create
    && var.agent_engine_config.identity_type == "SERVICE_ACCOUNT"
    ? toset(local.roles)
    : toset([])
  )
  role    = each.key
  project = local.project_id
  member  = google_service_account.service_account[0].member
}

resource "google_project_iam_member" "default" {
  for_each = (
    var.service_account_config.create
    && var.agent_engine_config.identity_type == "AGENT_IDENTITY"
    ? toset(local.roles)
    : toset([])
  )
  role    = each.key
  project = local.project_id
  # TBD once agent identity can be retrieved from Agent Engine
  member = "xxx"
}
