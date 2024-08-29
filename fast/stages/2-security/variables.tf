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

# Refer 
variable "cas_configs" {
  description = "The CAS CAs to add to each environment."
  type = object({
    dev = optional(map(object({
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
        subject = optional(object({
          common_name         = string
          organization        = string
          country_code        = optional(string)
          locality            = optional(string)
          organizational_unit = optional(string)
          postal_code         = optional(string)
          province            = optional(string)
          street_address      = optional(string)
          }), {
          common_name  = "test.example.com"
          organization = "Test Example"
        })
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
        ca_pool_id = optional(string, null)
        name       = optional(string, null)
        tier       = optional(string, "DEVOPS")
      })
      location              = string
      iam                   = optional(map(list(string)), {})
      iam_bindings          = optional(map(any), {})
      iam_bindings_additive = optional(map(any), {})
      iam_by_principals     = optional(map(list(string)), {})
    })), {})
    prod = optional(map(object({
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
        subject = optional(object({
          common_name         = string
          organization        = string
          country_code        = optional(string)
          locality            = optional(string)
          organizational_unit = optional(string)
          postal_code         = optional(string)
          province            = optional(string)
          street_address      = optional(string)
          }), {
          common_name  = "test.example.com"
          organization = "Test Example"
        })
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
        ca_pool_id = optional(string, null)
        name       = optional(string, null)
        tier       = optional(string, "DEVOPS")
      })
      location = string
      iam      = optional(map(list(string)), {})
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
      iam_by_principals = optional(map(list(string)), {})
    })), {})
  })
  nullable = false
  default = {
    dev  = {}
    prod = {}
  }
}

variable "essential_contacts" {
  description = "Email used for essential contacts, unset if null."
  type        = string
  default     = null
}

variable "kms_keys" {
  description = "KMS keys to create, keyed by name."
  type = map(object({
    rotation_period = optional(string, "7776000s")
    labels          = optional(map(string))
    locations = optional(list(string), [
      "europe", "europe-west1", "europe-west3", "global"
    ])
    purpose                       = optional(string, "ENCRYPT_DECRYPT")
    skip_initial_version_creation = optional(bool, false)
    version_template = optional(object({
      algorithm        = string
      protection_level = optional(string, "SOFTWARE")
    }))

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
  }))
  default  = {}
  nullable = false
}

variable "ngfw_tls_configs" {
  description = "The CAS and trust configurations key names to be used for NGFW Enterprise."
  type = object({
    keys = optional(object({
      dev = optional(object({
        cas           = optional(list(string), ["ngfw-dev-cas-0"])
        trust_configs = optional(list(string), ["ngfw-dev-tc-0"])
      }), {})
      prod = optional(object({
        cas           = optional(list(string), ["ngfw-prod-cas-0"])
        trust_configs = optional(list(string), ["ngfw-prod-tc-0"])
      }), {})
    }), {})
    tls_inspection = optional(object({
      enabled               = optional(bool, false)
      exclude_public_ca_set = optional(bool, false)
      min_tls_version       = optional(string, "TLS_1_0")
    }), {})
  })
  nullable = false
  default = {
    dev  = {}
    prod = {}
  }
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "trust_configs" {
  description = "The trust configs grouped by environment."
  type = object({
    dev = optional(map(object({
      description              = optional(string)
      location                 = string
      allowlisted_certificates = optional(map(string), {})
      trust_stores = optional(map(object({
        intermediate_cas = optional(map(string), {})
        trust_anchors    = optional(map(string), {})
      })), {})
    })))
    prod = optional(map(object({
      description              = optional(string)
      location                 = string
      allowlisted_certificates = optional(map(string), {})
      trust_stores = optional(map(object({
        intermediate_cas = optional(map(string), {})
        trust_anchors    = optional(map(string), {})
      })), {})
    })))
  })
  nullable = false
  default = {
    dev  = {}
    prod = {}
  }
}
