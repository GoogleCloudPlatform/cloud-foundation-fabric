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
  glb_create   = var.phpipam_exposure == "EXTERNAL"
  iap_sa_email = try(module.project.service_accounts.robots["iap"].email, "")
}

# Reserved static IP for the Load Balancer
module "addresses" {
  source           = "../../../modules/net-address"
  count            = local.glb_create ? 1 : 0
  project_id       = var.project_id
  global_addresses = ["phpipam"]
}

# Global L7 HTTPS Load Balancer in front of Cloud Run
module "glb" {
  source     = "../../../modules/net-lb-app-ext"
  count      = local.glb_create ? 1 : 0
  project_id = module.project.project_id
  name       = "phpipam-glb"
  address    = module.addresses.0.global_addresses["phpipam"].address
  protocol   = "HTTPS"

  backend_service_configs = {
    default = {
      backends = [
        { backend = "phpipam" }
      ]
      health_checks = []
      port_name     = "http"
      security_policy = try(google_compute_security_policy.policy[0].name,
      null)
      iap_config = try({
        oauth2_client_id     = google_iap_client.iap_client[0].client_id,
        oauth2_client_secret = google_iap_client.iap_client[0].secret
      }, null)
    }
  }
  health_check_configs = {}
  neg_configs = {
    phpipam = {
      cloudrun = {
        region = var.region
        target_service = {
          name = module.cloud_run.service_name
        }
      }
    }
  }
  ssl_certificates = {
    managed_configs = {
      default = {
        domains = [local.domain]
      }
    }
  }
}

# Cloud Armor configuration
resource "google_compute_security_policy" "policy" {
  count   = local.glb_create && var.security_policy.enabled ? 1 : 0
  project = module.project.project_id
  name    = "cloud-run-policy"

  rule {
    action   = "deny(403)"
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.security_policy.ip_blacklist
      }
    }
    description = "Deny access to list of IPs"
  }
  rule {
    action   = "deny(403)"
    priority = 900
    match {
      expr {
        expression = "request.path.matches(\"${var.security_policy.path_blocked}\")"
      }
    }
    description = "Deny access to specific URL paths"
  }
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule"
  }
}

# Identity-Aware Proxy (IAP) or OAuth brand (see OAuth consent screen)
# Note:
# Only "Organization Internal" brands can be created programmatically
# via API. To convert it into an external brand please use the GCP
# Console.
# Brands can only be created once for a Google Cloud project and the
# underlying Google API doesn't support DELETE or PATCH methods.
# Destroying a Terraform-managed Brand will remove it from state but
# will not delete it from Google Cloud.
resource "google_iap_brand" "iap_brand" {
  count   = local.glb_create && var.iap.enabled ? 1 : 0
  project = module.project.project_id
  # Support email displayed on the OAuth consent screen. The caller must be
  # the user with the associated email address, or if a group email is
  # specified, the caller can be either a user or a service account which
  # is an owner of the specified group in Cloud Identity.
  support_email     = var.iap.email
  application_title = var.iap.app_title
}

# IAP owned OAuth2 client
# Note:
# Only internal org clients can be created via declarative tools.
# External clients must be manually created via the GCP console.
# Warning:
# All arguments including secret will be stored in the raw state as plain-text.
resource "google_iap_client" "iap_client" {
  count        = local.glb_create && var.iap.enabled ? 1 : 0
  display_name = var.iap.oauth2_client_name
  brand        = google_iap_brand.iap_brand[0].name
}

# IAM policy for IAP
# For simplicity we use the same email as support_email and authorized member
resource "google_iap_web_iam_member" "iap_iam" {
  count   = local.glb_create && var.iap.enabled ? 1 : 0
  project = module.project.project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = "user:${var.iap.email}"
}
