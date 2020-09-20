/**
 * Copyright 2020 Google LLC
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
  address_name        = var.address_name != null ? var.address_name : google_compute_global_address.address[0].name
  cert_domains        = var.cert_domains
  cert_name           = var.cert_name != null ? var.cert_name : google_compute_managed_ssl_certificate.cert[0].name
  iap_client_id       = var.iap_client_id
  iap_client_secret   = var.iap_client_secret
  name                = var.name
  web_user_principals = var.web_user_principals
  project_id          = var.project_id
  loadbalancer_ip    = var.address_name != null ? data.google_compute_global_address.address[0].address : google_compute_global_address.address[0].address
}

data "google_compute_global_address" "address" {
  count = var.address_name != null ? 1 : 0
  project = local.project_id
  name = var.address_name
}

resource "google_compute_global_address" "address" {
  count = var.address_name != null ? 0 : 1
  name  = local.name
}

resource "google_compute_managed_ssl_certificate" "cert" {
  provider = google-beta

  count = local.cert_domains == null ? 0 : 1

  name = local.name

  managed {
    domains = local.cert_domains
  }
}

resource "google_project_iam_member" "web_users" {
  for_each = toset(local.web_user_principals)
  project  = local.project_id
  role     = "roles/iap.httpsResourceAccessor"
  member   = each.key
}

# Project-level conditions are in private beta and Terraform support for setting
# them is not yet available.
#resource "google_project_iam_member" "web_users_conditional" {
#  for_each = toset(local.web_user_principals_conditional)
#  provider   = google-beta
#  role     = "roles/iap.httpsResourceAccessor"
#  member   = each.key
#  condition {
#    title       = "only_from_access_level"
#    description = "Allow access only if it matches the access level."
#    expression  = "'${local.access_level_name}' in request.auth.access_levels"
#  }
#}

resource "helm_release" "iap_connector" {
  name            = "iap-connector"
  chart           = "${path.module}/iap-connector"
  cleanup_on_fail = true
  reset_values    = true
  timeout         = 600

  set {
    name  = "oauth.client.id"
    value = base64encode(local.iap_client_id)
  }
  set_sensitive {
    name  = "oauth.client.secret"
    value = base64encode(local.iap_client_secret)
  }

  set {
    name  = "ingresses[0].name"
    value = "ingress"
  }

  set {
    name  = "ingresses[0].enable_container_native_lb"
    value = "true"
  }

  set {
    name  = "ingresses[0].externalIpName"
    value = local.address_name
  }

  set {
    name  = "ingresses[0].certs[0]"
    value = local.cert_name
  }

  values = ["{ \"mappings\": ${jsonencode(var.mappings)} }"]
}
