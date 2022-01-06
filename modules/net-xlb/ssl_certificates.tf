/**
 * Copyright 2021 Google LLC
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
  # Defaults
  ssl_certificate_configs = {
    source_type = try(var.ssl_certificate_configs.source_type, "create")
    type        = try(var.ssl_certificate_configs.type, "managed")
    id          = try(var.ssl_certificate_configs.id, null)
    domains     = try(var.ssl_certificate_configs.domains, ["my_test_domain.com"])
    opts = {
      common_name           = try(var.ssl_certificate_configs.opts.common_name, var.ssl_certificate_configs.domains.0, "my_test_domain.com")
      organization          = try(var.ssl_certificate_configs.opts.organization, "My organization")
      alghorithm            = try(var.ssl_certificate_configs.opts.organization, "RSA")
      rsa_bits              = try(var.ssl_certificate_configs.opts.organization, 2048)
      validity_period_hours = try(var.ssl_certificate_configs.opts.organization, 8760) # 1 year
      early_renewal_hours   = try(var.ssl_certificate_configs.opts.organization, 12)
      allowed_uses = try(
        var.ssl_certificate_configs.opts.organization,
        [
          "key_encipherment",
          "digital_signature",
          "server_auth",
        ]
      )
    }
  }

  create_managed = (
    var.https
    && local.ssl_certificate_configs.source_type == "create"
    && local.ssl_certificate_configs.type == "managed"
    ? 1
    : 0
  )
  create_unmanaged = (
    var.https
    && local.ssl_certificate_configs.source_type == "create"
    && local.ssl_certificate_configs.type == "unmanaged"
    ? 1
    : 0
  )
}

resource "google_compute_managed_ssl_certificate" "managed" {
  count   = local.create_managed
  project = var.project_id
  name    = var.name
  managed {
    domains = local.ssl_certificate_configs.domains
  }
}

resource "google_compute_ssl_certificate" "unmanaged" {
  count       = local.create_unmanaged
  name        = var.name
  private_key = tls_private_key.self_signed_key.0.private_key_pem
  certificate = tls_self_signed_cert.self_signed_cert.0.cert_pem
}

resource "tls_private_key" "self_signed_key" {
  count     = local.create_unmanaged
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "self_signed_cert" {
  count                 = local.create_unmanaged
  key_algorithm         = tls_private_key.self_signed_key.0.algorithm
  private_key_pem       = tls_private_key.self_signed_key.0.private_key_pem
  validity_period_hours = local.ssl_certificate_configs.opts.validity_period_hours
  early_renewal_hours   = local.ssl_certificate_configs.opts.early_renewal_hours
  allowed_uses          = local.ssl_certificate_configs.opts.allowed_uses
  dns_names             = local.ssl_certificate_configs.domains

  subject {
    common_name  = local.ssl_certificate_configs.opts.common_name
    organization = local.ssl_certificate_configs.opts.organization
  }
}
