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
  cert_subjects = [
    {
      country             = "IT"
      province            = "Lombardy"
      locality            = "Milan"
      common_name         = "Gitlab CA"
      organization        = "Example"
      organizational_unit = "Example"
    }
  ]
}

#######################################################################
#                      GITLAB CA PRIVATE KEY                          #
#######################################################################

resource "tls_private_key" "gitlab_ca_private_key" {
  algorithm = "RSA"
}

resource "local_file" "gitlab_ca_private_key" {
  content  = tls_private_key.gitlab_ca_private_key.private_key_pem
  filename = "${path.module}/certs/${var.gitlab_config.hostname}.ca.key"
}

#######################################################################
#                          GITLAB CA CERT                             #
#######################################################################

resource "tls_self_signed_cert" "gitlab_ca_cert" {
  private_key_pem   = tls_private_key.gitlab_ca_private_key.private_key_pem
  is_ca_certificate = true
  dynamic "subject" {
    for_each = toset(local.cert_subjects)
    content {
      country             = subject.value.country
      province            = subject.value.province
      locality            = subject.value.locality
      common_name         = subject.value.common_name
      organization        = subject.value.organization
      organizational_unit = subject.value.organizational_unit
    }
  }
  validity_period_hours = 43800 //  1825 days or 5 years
  allowed_uses          = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

resource "local_file" "gitlab_ca_cert" {
  content  = tls_self_signed_cert.gitlab_ca_cert.cert_pem
  filename = "${path.module}/certs/${var.gitlab_config.hostname}.ca.crt"
}

#######################################################################
#                    SERVER CERT SIGNED BY CA                         #
#######################################################################

resource "tls_private_key" "gitlab_server_key" {
  algorithm = "RSA"
}

resource "local_file" "gitlab_server_key" {
  content  = tls_private_key.gitlab_server_key.private_key_pem
  filename = "${path.module}/certs/${var.gitlab_config.hostname}.key"
}

# Create CSR for Gitlab Server certificate
resource "tls_cert_request" "gitlab_server_csr" {
  private_key_pem = tls_private_key.gitlab_server_key.private_key_pem
  dns_names       = [var.gitlab_config.hostname]

  dynamic "subject" {
    for_each = toset(local.cert_subjects)
    content {
      country             = subject.value.country
      province            = subject.value.province
      locality            = subject.value.locality
      common_name         = subject.value.common_name
      organization        = subject.value.organization
      organizational_unit = subject.value.organizational_unit
    }
  }
}

resource "tls_locally_signed_cert" "gitlab_server_singed_cert" {
  cert_request_pem   = tls_cert_request.gitlab_server_csr.cert_request_pem
  ca_private_key_pem = tls_private_key.gitlab_ca_private_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.gitlab_ca_cert.cert_pem

  validity_period_hours = 43800

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "local_file" "gitlab_server_crt" {
  content  = tls_locally_signed_cert.gitlab_server_singed_cert.cert_pem
  filename = "${path.module}/certs/${var.gitlab_config.hostname}.crt"
}