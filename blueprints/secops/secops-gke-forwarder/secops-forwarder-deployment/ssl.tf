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
  self_signed_certs_for_tenant = {
    for k, v in var.tenants : k => v if v.forwarder_config.tls_config.required && v.forwarder_config.tls_config.cert_key == null
  }
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
#                    FORWARDER CA PRIVATE KEY                         #
#######################################################################

resource "tls_private_key" "forwarder_ca_private_key" {
  for_each  = local.self_signed_certs_for_tenant
  algorithm = "RSA"
}

#######################################################################
#                        FORWARDER CA CERT                            #
#######################################################################

resource "tls_self_signed_cert" "forwarder_ca_cert" {
  for_each          = local.self_signed_certs_for_tenant
  private_key_pem   = tls_private_key.forwarder_ca_private_key[each.key].private_key_pem
  is_ca_certificate = true
  dynamic "subject" {
    for_each = toset(local.cert_subjects)
    content {
      country             = subject.value.country
      province            = subject.value.province
      locality            = subject.value.locality
      common_name         = "Chronicle Forwarder"
      organization        = subject.value.organization
      organizational_unit = each.value.tenant_id
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

resource "tls_private_key" "forwarder_server_key" {
  for_each  = local.self_signed_certs_for_tenant
  algorithm = "RSA"
}

resource "tls_cert_request" "forwarder_server_csr" {
  for_each        = local.self_signed_certs_for_tenant
  private_key_pem = tls_private_key.forwarder_server_key[each.key].private_key_pem
  dns_names       = ["${each.value.tenant_id}.chronicle-forwarder.gke"]

  dynamic "subject" {
    for_each = toset(local.cert_subjects)
    content {
      country             = subject.value.country
      province            = subject.value.province
      locality            = subject.value.locality
      common_name         = "Gitlab"
      organization        = subject.value.organization
      organizational_unit = each.value.tenant_id
    }
  }
}

resource "tls_locally_signed_cert" "forwarder_server_singed_cert" {
  for_each           = local.self_signed_certs_for_tenant
  cert_request_pem   = tls_cert_request.forwarder_server_csr[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.forwarder_ca_private_key[each.key].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.forwarder_ca_cert[each.key].cert_pem

  validity_period_hours = 87600 //  3650 days or 10 years

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}
