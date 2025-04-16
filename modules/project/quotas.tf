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
  _quota_factory_path = pathexpand(coalesce(var.factories_config.quotas, "-"))
  _quota_factory_data_raw = merge([
    for f in try(fileset(local._quota_factory_path, "*.yaml"), []) :
    yamldecode(file("${local._quota_factory_path}/${f}"))
  ]...)
  # simulate applying defaults to data coming from yaml files
  _quota_factory_data = {
    for k, v in local._quota_factory_data_raw :
    k => merge({
      dimensions           = {}
      justification        = null
      contact_email        = null
      annotations          = null
      ignore_safety_checks = null
    }, v)
  }
  quotas = merge(local._quota_factory_data, var.quotas)
}

resource "google_cloud_quotas_quota_preference" "default" {
  for_each      = local.quotas
  parent        = "projects/${local.project.project_id}"
  name          = each.key
  service       = each.value.service
  dimensions    = each.value.dimensions
  quota_id      = each.value.quota_id
  contact_email = each.value.contact_email
  justification = each.value.justification
  quota_config {
    preferred_value = each.value.preferred_value
    annotations     = each.value.annotations
  }
  ignore_safety_checks = each.value.ignore_safety_checks
  depends_on = [
    google_project_service.project_services
  ]
}
