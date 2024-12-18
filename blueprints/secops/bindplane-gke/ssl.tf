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
  bootstrap_self_signed_cert = var.bindplane_config.tls_certificate_cer == null || var.bindplane_config.tls_certificate_key == null
  cert_subjects = [
    {
      country             = "IT"
      province            = "Lombardy"
      locality            = "Milan"
      organization        = "Example"
      organizational_unit = "Example"
    }
  ]
}

#######################################################################
#                         CA PRIVATE KEY                              #
#######################################################################

resource "tls_private_key" "ca_private_key" {
  count     = local.bootstrap_self_signed_cert ? 1 : 0
  algorithm = "RSA"
}

#######################################################################
#                            CA CERT                                  #
#######################################################################

resource "tls_self_signed_cert" "ca_cert" {
  count             = local.bootstrap_self_signed_cert ? 1 : 0
  private_key_pem   = tls_private_key.ca_private_key.0.private_key_pem
  is_ca_certificate = true
  dynamic "subject" {
    for_each = toset(local.cert_subjects)
    content {
      country             = subject.value.country
      province            = subject.value.province
      locality            = subject.value.locality
      common_name         = "Bindplane"
      organization        = subject.value.organization
      organizational_unit = subject.value.organization
    }
  }
  validity_period_hours = 87600 //  3650 days or 10 years
  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

#######################################################################
#                    SERVER CERT SIGNED BY CA                         #
#######################################################################

resource "tls_private_key" "server_key" {
  count     = local.bootstrap_self_signed_cert ? 1 : 0
  algorithm = "RSA"
}

resource "tls_cert_request" "server_csr" {
  count           = local.bootstrap_self_signed_cert ? 1 : 0
  private_key_pem = tls_private_key.server_key.0.private_key_pem
  dns_names       = ["${var.dns_config.hostname}.${var.dns_config.domain}"]

  dynamic "subject" {
    for_each = toset(local.cert_subjects)
    content {
      country             = subject.value.country
      province            = subject.value.province
      locality            = subject.value.locality
      common_name         = "Gitlab"
      organization        = subject.value.organization
      organizational_unit = subject.value.organization
    }
  }
}

resource "tls_locally_signed_cert" "server_singed_cert" {
  count              = local.bootstrap_self_signed_cert ? 1 : 0
  cert_request_pem   = tls_cert_request.server_csr.0.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_private_key.0.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.0.cert_pem

  validity_period_hours = 87600 //  3650 days or 10 years

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}
