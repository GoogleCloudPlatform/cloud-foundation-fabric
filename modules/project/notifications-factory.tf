/**
 * Copyright 2024 Google LLC
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
  _channels_factory_data_raw = merge([
    for f in try(fileset(var.factories_config.channels, "*.yaml"), []) :
    yamldecode(file("${var.factories_config.channels}/${f}"))
  ]...)
  _channels_factory_data = {
    for k, v in local._channels_factory_data_raw :
    k => merge({
      name             = k
      type             = null
      email_address    = null
      display_name     = null
      labels           = {}
      sensitive_labels = []
      user_labels      = {}
      enabled          = null
      description      = null
    }, v)
  }
  channels = merge(local._channels_factory_data, var.channels)
}

resource "google_monitoring_notification_channel" "default" {
  count   = var.default_alerts_email != null ? 1 : 0
  project = "jetstack-joshua-wright"
  # project      = local.project.project_id
  display_name = "Default Email Notification"
  type         = "email"
  labels = {
    email_address = var.default_alerts_email
  }
}

resource "google_monitoring_notification_channel" "this" {
  for_each = local.channels
  project  = "jetstack-joshua-wright"
  # project      = local.project.project_id
  enabled      = each.value.enabled
  display_name = each.value.display_name
  type         = each.value.type
  labels       = each.value.labels
  user_labels  = each.value.user_labels
  description  = each.value.description
  dynamic "sensitive_labels" {
    for_each = lookup(each.value, "sensitive_labels", null)[*]
    content {
      auth_token  = try(each.value.sensitive_labels.auth_token, null)
      password    = try(each.value.sensitive_labels.password, null)
      service_key = try(each.value.sensitive_labels.service_key, null)
    }
  }
}


