/**
 * Copyright 2026 Google LLC
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

# tfdoc:file:description Authorization extensions and policies.

locals {
  # Model Armor expects fully qualified template ids: short ids are
  # expanded against the gateway project and location.
  _model_armor_templates = {
    for k in ["request_template_id", "response_template_id"] :
    k => (
      length(split("/", local._model_armor_template_ids[k])) > 1
      ? local._model_armor_template_ids[k]
      : join("/", [
        "projects", local.project_id, "locations", local.location,
        "templates", local._model_armor_template_ids[k]
      ])
    )
  }
  _model_armor_template_ids = {
    for k in ["request_template_id", "response_template_id"] :
    k => lookup(
      local.ctx.model_armor_templates,
      try(var.model_armor_config[k], ""),
      try(var.model_armor_config[k], "")
    )
  }
  iap_name = try(
    coalesce(var.iap_config.name, "${var.name}-iap"), null
  )
  model_armor_name = try(
    coalesce(var.model_armor_config.name, "${var.name}-ma"), null
  )
}

resource "google_network_services_authz_extension" "iap" {
  provider  = google-beta
  count     = var.iap_config == null ? 0 : 1
  project   = local.project_id
  location  = local.location
  name      = local.iap_name
  service   = "iap.googleapis.com"
  fail_open = var.iap_config.fail_open
  timeout   = var.iap_config.timeout
  metadata = merge(
    { iapPolicyVersion = var.iap_config.policy_version },
    var.iap_config.iam_enforcement_mode == null ? {} : {
      iamEnforcementMode = var.iap_config.iam_enforcement_mode
    }
  )
}

resource "google_network_security_authz_policy" "iap" {
  provider       = google-beta
  count          = var.iap_config == null ? 0 : 1
  project        = local.project_id
  location       = local.location
  name           = local.iap_name
  action         = "CUSTOM"
  policy_profile = "REQUEST_AUTHZ"

  target {
    resources = [google_network_services_agent_gateway.default.id]
  }

  custom_provider {
    authz_extension {
      resources = [google_network_services_authz_extension.iap[0].id]
    }
  }
}

resource "google_network_services_authz_extension" "model_armor" {
  provider  = google-beta
  count     = var.model_armor_config == null ? 0 : 1
  project   = local.project_id
  location  = local.location
  name      = local.model_armor_name
  service   = "modelarmor.${local.location}.rep.googleapis.com"
  fail_open = var.model_armor_config.fail_open
  timeout   = var.model_armor_config.timeout
  metadata = {
    model_armor_settings = jsonencode([local._model_armor_templates])
  }
}

resource "google_network_security_authz_policy" "model_armor" {
  provider       = google-beta
  count          = var.model_armor_config == null ? 0 : 1
  project        = local.project_id
  location       = local.location
  name           = local.model_armor_name
  action         = "CUSTOM"
  policy_profile = "CONTENT_AUTHZ"

  target {
    resources = [google_network_services_agent_gateway.default.id]
  }

  custom_provider {
    authz_extension {
      resources = [
        google_network_services_authz_extension.model_armor[0].id
      ]
    }
  }

  dynamic "http_rules" {
    for_each = (
      length(var.model_armor_config.authz_hosts) > 0 ? [""] : []
    )
    content {
      to {
        operations {
          dynamic "hosts" {
            for_each = var.model_armor_config.authz_hosts
            content {
              exact = hosts.value
            }
          }
        }
      }
    }
  }

  # Policies on the same gateway cannot be created concurrently.
  depends_on = [google_network_security_authz_policy.iap]
}
