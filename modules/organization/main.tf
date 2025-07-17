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

locals {
  ctx = {
    custom_roles = {
      # mixing in locally managed roles triggers a cycle
      for k, v in var.factories_config.context.custom_roles :
      "${local.ctx_p}custom_roles:${k}" => v
    }
    iam_principals = {
      for k, v in var.factories_config.context.iam_principals :
      "${local.ctx_p}iam_principals:${k}" => v
    }
    tag_keys = {
      for k, v in var.factories_config.context.tag_keys :
      "${local.ctx_p}tag_keys:${k}" => v
    }
    tag_values = {
      for k, v in var.factories_config.context.tag_values :
      "${local.ctx_p}tag_values:${k}" => v
    }
  }
  ctx_p = "$"
  organization_id_numeric = split("/", var.organization_id)[1]
}

resource "google_essential_contacts_contact" "contact" {
  provider                            = google-beta
  for_each                            = var.contacts
  parent                              = var.organization_id
  email                               = each.key
  language_tag                        = "en"
  notification_category_subscriptions = each.value
  depends_on = [
    google_organization_iam_binding.authoritative,
    google_organization_iam_binding.bindings,
    google_organization_iam_member.bindings
  ]
}


resource "google_compute_firewall_policy_association" "default" {
  count             = var.firewall_policy == null ? 0 : 1
  attachment_target = var.organization_id
  name              = var.firewall_policy.name
  firewall_policy   = var.firewall_policy.policy
}
