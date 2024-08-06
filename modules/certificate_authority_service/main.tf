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

resource "google_privateca_ca_pool" "ca_pool" {
  count    = var.ca_pool_config.ca_pool_id == null ? 1 : 0
  name     = var.ca_pool_config.name
  project  = var.project_id
  location = "europe-west8"
  tier     = "DEVOPS"
}

resource "google_privateca_certificate_authority" "cas" {
  for_each = var.ca_configs
  pool = coalesce(
    var.ca_pool_config.ca_pool_id == null,
    try(google_privateca_ca_pool.ca_pool[0].name, null)
  )
  certificate_authority_id = each.key
  project                  = var.project_id
  location                 = var.location
  type                     = each.value.type
  deletion_protection      = each.value.deletion_protection
  lifetime                 = each.value.lifetime

  config {
    subject_config {
      subject {
        organization = each.value.subject.organization
        common_name  = each.value.subject.common_name
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
          key_agreement      = each.value.key_usage.key_agreement
          key_encipherment   = each.value.key_usage.key_encipherment
        }
        extended_key_usage {
          client_auth      = each.value.key_usage.client_auth
          code_signing     = each.value.key_usage.code_signing
          email_protection = each.value.key_usage.email_protection
          server_auth      = each.value.key_usage.server_auth
          time_stamping    = each.value.key_usage.time_stamping
        }
      }
    }
  }

  key_spec {
    algorithm = each.value.key_spec_algorithm
  }
}
