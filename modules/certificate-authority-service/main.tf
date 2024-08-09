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
  _ca_pool_id_list = try(split("/", var.ca_pool_config.ca_pool_id), [])
  ca_pool_id = coalesce(
    var.ca_pool_config.ca_pool_id,
    try(google_privateca_ca_pool.ca_pool[0].id, null)
  )
  ca_pool_name = coalesce(
    try(element(local._ca_pool_id_list, length(local._ca_pool_id_list) - 1), null),
    try(google_privateca_ca_pool.ca_pool[0].name, null)
  )
}

resource "google_privateca_ca_pool" "ca_pool" {
  count    = var.ca_pool_config.ca_pool_id == null ? 1 : 0
  name     = var.ca_pool_config.name
  project  = var.project_id
  location = var.location
  tier     = var.ca_pool_config.tier
}

resource "google_privateca_certificate_authority" "cas" {
  for_each                               = var.ca_configs
  pool                                   = local.ca_pool_name
  certificate_authority_id               = each.key
  project                                = var.project_id
  location                               = var.location
  type                                   = each.value.type
  deletion_protection                    = each.value.deletion_protection
  lifetime                               = each.value.lifetime
  pem_ca_certificate                     = each.value.pem_ca_certificate
  ignore_active_certificates_on_deletion = each.value.ignore_active_certificates_on_deletion
  skip_grace_period                      = each.value.skip_grace_period
  gcs_bucket                             = each.value.gcs_bucket
  labels                                 = each.value.labels

  config {
    subject_config {
      subject {
        common_name         = each.value.subject.common_name
        country_code        = each.value.subject.country_code
        organizational_unit = each.value.subject.organizational_unit
        locality            = each.value.subject.locality
        organization        = each.value.subject.organization
        province            = each.value.subject.province
        street_address      = each.value.subject.street_address
        postal_code         = each.value.subject.postal_code
      }
      dynamic "subject_alt_name" {
        for_each = each.value.subject_alt_name != null ? [1] : []
        content {
          dns_names       = each.value.subject_alt_name.dns_names
          email_addresses = each.value.subject_alt_name.email_addresses
          ip_addresses    = each.value.subject_alt_name.ip_addresses
          uris            = each.value.subject_alt_name.uris
        }
      }
    }
    x509_config {
      ca_options {
        is_ca = each.value.is_ca
      }
      key_usage {
        base_key_usage {
          cert_sign          = each.value.key_usage.cert_sign
          content_commitment = each.value.key_usage.content_commitment
          crl_sign           = each.value.key_usage.crl_sign
          data_encipherment  = each.value.key_usage.data_encipherment
          decipher_only      = each.value.key_usage.decipher_only
          digital_signature  = each.value.key_usage.digital_signature
          encipher_only      = each.value.key_usage.encipher_only
          key_agreement      = each.value.key_usage.key_agreement
          key_encipherment   = each.value.key_usage.key_encipherment
        }
        extended_key_usage {
          client_auth      = each.value.key_usage.client_auth
          code_signing     = each.value.key_usage.code_signing
          email_protection = each.value.key_usage.email_protection
          ocsp_signing     = each.value.key_usage.ocsp_signing
          server_auth      = each.value.key_usage.server_auth
          time_stamping    = each.value.key_usage.time_stamping
        }
      }
    }
  }

  key_spec {
    algorithm             = each.value.key_spec.algorithm
    cloud_kms_key_version = each.value.key_spec.kms_key_id
  }

  dynamic "subordinate_config" {
    for_each = each.value.subordinate_config != null ? [1] : []
    content {
      certificate_authority = each.value.subordinate_config.root_ca_id
      dynamic "pem_issuer_chain" {
        for_each = (
          each.value.subordinate_config.pem_issuer_certificates != null
          ? [1] : []
        )
        content {
          pem_certificates = each.value.subordinate_config.pem_issuer_certificates
        }
      }
    }
  }
}
