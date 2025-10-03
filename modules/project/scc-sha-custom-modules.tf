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

# tfdoc:file:description Project-level Custom modules with Security Health Analytics.

locals {
  _scc_sha_custom_modules_factory_path = pathexpand(coalesce(var.factories_config.scc_sha_custom_modules, "-"))
  _scc_sha_custom_modules_factory_data_raw = merge([
    for f in try(fileset(local._scc_sha_custom_modules_factory_path, "*.yaml"), []) :
    yamldecode(file("${local._scc_sha_custom_modules_factory_path}/${f}"))
  ]...)
  _scc_sha_custom_modules_factory_data = {
    for k, v in local._scc_sha_custom_modules_factory_data_raw :
    k => {
      description       = try(v.description, null)
      severity          = v.severity
      recommendation    = v.recommendation
      predicate         = v.predicate
      resource_selector = v.resource_selector
      enablement_state  = try(v.enablement_state, "ENABLED")
    }
  }
  _scc_sha_custom_modules = merge(
    local._scc_sha_custom_modules_factory_data,
    var.scc_sha_custom_modules
  )
  scc_sha_custom_modules = {
    for k, v in local._scc_sha_custom_modules :
    k => merge(v, {
      name   = k
      parent = "projects/${local.project.project_id}"
    })
  }
}

resource "google_scc_management_project_security_health_analytics_custom_module" "scc_project_custom_module" {
  provider = google

  for_each     = local.scc_sha_custom_modules
  project      = local.project.project_id
  location     = "global"
  display_name = each.value.name
  custom_config {
    predicate {
      expression = each.value.predicate.expression
    }
    resource_selector {
      resource_types = each.value.resource_selector.resource_types
    }
    description    = each.value.description
    recommendation = each.value.recommendation
    severity       = each.value.severity
  }
  enablement_state = each.value.enablement_state
}
