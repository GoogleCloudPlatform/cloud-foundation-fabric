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
  _channels_factory_data_raw = merge([
    for f in try(fileset(var.factories_config.channels, "*.yaml"), []) :
    yamldecode(file("${var.factories_config.channels}/${f}"))
  ]...)
  # TODO: do we want to allow multiple channels in a single file?
  _channels_factory_data = {
    for k, v in local._channels_factory_data_raw :
    k => {
      type         = v.type
      description  = try(v.description, null)
      display_name = try(v.display_name, null)
      enabled      = null
      labels       = try(v.labels, null)
      sensitive_labels = !can(v.sensitive_labels) ? null : {
        auth_token  = try(v.sensitive_labels.auth_token, null)
        password    = try(v.sensitive_labels.password, null)
        service_key = try(v.sensitive_labels.service_key, null)
      }
      user_labels = try(v.user_labels, null)
    }
  }
  channels = merge(local._channels_factory_data, var.notification_channels)
}

resource "google_monitoring_notification_channel" "channels" {
  for_each     = local.channels
  project      = local.project.project_id
  enabled      = each.value.enabled
  display_name = each.value.display_name
  type         = each.value.type
  labels       = each.value.labels
  user_labels  = each.value.user_labels
  description  = each.value.description
  dynamic "sensitive_labels" {
    for_each = each.value.sensitive_labels[*]
    content {
      auth_token  = sensitive_labels.value.auth_token
      password    = sensitive_labels.value.password
      service_key = sensitive_labels.value.service_key
    }
  }
}


