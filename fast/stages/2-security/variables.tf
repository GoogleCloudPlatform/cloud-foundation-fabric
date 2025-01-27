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

variable "certificate_authorities" {
  description = "Certificate Authority Service pool and CAs. If environments is null identical pools and CAs are created in all environments."
  type = map(object({
    location              = string
    environments          = optional(list(string))
    iam                   = optional(map(list(string)), {})
    iam_bindings          = optional(map(any), {})
    iam_bindings_additive = optional(map(any), {})
    iam_by_principals     = optional(map(list(string)), {})
    ca_configs = map(object({
      deletion_protection                    = optional(string, true)
      type                                   = optional(string, "SELF_SIGNED")
      is_ca                                  = optional(bool, true)
      lifetime                               = optional(string, null)
      pem_ca_certificate                     = optional(string, null)
      ignore_active_certificates_on_deletion = optional(bool, false)
      skip_grace_period                      = optional(bool, true)
      labels                                 = optional(map(string), null)
      gcs_bucket                             = optional(string, null)
      key_spec = optional(object({
        algorithm  = optional(string, "RSA_PKCS1_2048_SHA256")
        kms_key_id = optional(string, null)
      }), {})
      key_usage = optional(object({
        cert_sign          = optional(bool, true)
        client_auth        = optional(bool, false)
        code_signing       = optional(bool, false)
        content_commitment = optional(bool, false)
        crl_sign           = optional(bool, true)
        data_encipherment  = optional(bool, false)
        decipher_only      = optional(bool, false)
        digital_signature  = optional(bool, false)
        email_protection   = optional(bool, false)
        encipher_only      = optional(bool, false)
        key_agreement      = optional(bool, false)
        key_encipherment   = optional(bool, true)
        ocsp_signing       = optional(bool, false)
        server_auth        = optional(bool, true)
        time_stamping      = optional(bool, false)
      }), {})
      subject = optional(
        object({
          common_name         = string
          organization        = string
          country_code        = optional(string)
          locality            = optional(string)
          organizational_unit = optional(string)
          postal_code         = optional(string)
          province            = optional(string)
          street_address      = optional(string)
        }),
        {
          common_name  = "test.example.com"
          organization = "Test Example"
        }
      )
      subject_alt_name = optional(object({
        dns_names       = optional(list(string), null)
        email_addresses = optional(list(string), null)
        ip_addresses    = optional(list(string), null)
        uris            = optional(list(string), null)
      }), null)
      subordinate_config = optional(object({
        root_ca_id              = optional(string)
        pem_issuer_certificates = optional(list(string))
      }), null)
    }))
    ca_pool_config = object({
      create_pool = optional(object({
        name = string
        tier = optional(string, "DEVOPS")
      }))
      use_pool = optional(object({
        id = string
      }))
    })
  }))
  nullable = false
  default  = {}
}

variable "essential_contacts" {
  description = "Email used for essential contacts, unset if null."
  type        = string
  default     = null
}

variable "kms_keys" {
  description = "KMS keys to create, keyed by name."
  type = map(object({
    iam = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      members = list(string)
      role    = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    iam_bindings_additive = optional(map(object({
      member = string
      role   = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    labels = optional(map(string))
    locations = optional(list(string), [
      "europe", "europe-west1", "europe-west3", "global"
    ])
    purpose                       = optional(string, "ENCRYPT_DECRYPT")
    rotation_period               = optional(string, "7776000s")
    skip_initial_version_creation = optional(bool, false)
    version_template = optional(object({
      algorithm        = string
      protection_level = optional(string, "SOFTWARE")
    }))
  }))
  default  = {}
  nullable = false
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}
