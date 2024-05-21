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

resource "google_privateca_ca_pool" "default" {
  project  = var.project_id
  name     = "Acme-CA-pool"
  location = var.region
  tier     = "ENTERPRISE"
}

resource "google_privateca_certificate_authority" "default" {
  project                  = var.project_id
  certificate_authority_id = "Acme-CA"
  location                 = var.region
  pool                     = google_privateca_ca_pool.default.name
  config {
    subject_config {
      subject {
        common_name  = "Acme-CA"
        organization = "Acme"
      }
    }
    x509_config {
      ca_options {
        is_ca = true
      }
      key_usage {
        base_key_usage {
          cert_sign = true
          crl_sign  = true
        }
        extended_key_usage {
          client_auth = true
          server_auth = true
        }
      }
    }
  }
  lifetime = "31536000s" // 1 year
  key_spec {
    algorithm = "EC_P256_SHA256"
  }

  // Disable CA deletion related safe checks for easier cleanup while testing.
  deletion_protection                    = false
  skip_grace_period                      = true
  ignore_active_certificates_on_deletion = true
}

# TLS certificate for the ILB
#
resource "tls_private_key" "ilb_cert_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "google_privateca_certificate" "ilb_cert" {
  project               = var.project_id
  certificate_authority = google_privateca_certificate_authority.default.certificate_authority_id
  location              = var.region
  pool                  = google_privateca_ca_pool.default.name
  lifetime              = "2592000s" // 30 days
  name                  = var.cloudrun_svcname
  config {
    subject_config {
      subject {
        common_name  = var.custom_domain
        organization = "Acme"
      }
      subject_alt_name {
        dns_names = [var.custom_domain]
      }
    }
    x509_config {
      ca_options {
        is_ca = false
      }
      key_usage {
        base_key_usage {
          key_agreement = true
        }
        extended_key_usage {
          server_auth = true
        }
      }
    }
    public_key {
      format = "PEM"
      key    = base64encode(tls_private_key.ilb_cert_key.public_key_pem)
    }
  }
}

# TLS certificate to secure the control plane/data plane Kong communication
#
resource "tls_private_key" "kong" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "kong" {
  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
  private_key_pem       = tls_private_key.kong.private_key_pem
  validity_period_hours = 365 * 24 // 1 year
  is_ca_certificate     = true
  subject {
    common_name = "kong_clustering"
  }
}