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

variable "ca_configs" {
  description = "The CA configurations."
  type = map(object({
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
  nullable = false
  default = {
    test-ca = {}
  }
  validation {
    condition = (
      length([
        for _, v in var.ca_configs
        : v.type
        if v.type != null
        && !contains(["SELF_SIGNED", "SUBORDINATE"], v.type)
      ]) == 0
    )
    error_message = "Type can only be `SELF_SIGNED` or `SUBORDINATE`."
  }
  validation {
    condition = (
      length([
        for _, v in var.ca_configs
        : v.key_spec.algorithm
        if v.key_spec.algorithm != null
        && !contains([
          "EC_P256_SHA256",
          "EC_P384_SHA384",
          "RSA_PSS_2048_SHA256",
          "RSA_PSS_3072_SHA256",
          "RSA_PSS_4096_SHA256",
          "RSA_PKCS1_2048_SHA256",
          "RSA_PKCS1_3072_SHA256",
          "RSA_PKCS1_4096_SHA256",
          "SIGN_HASH_ALGORITHM_UNSPECIFIED"
        ], v.key_spec.algorithm)
      ]) == 0
    )
    error_message = <<EOT
    Algorithm can only be `SIGN_HASH_ALGORITHM_UNSPECIFIED`,
    `RSA_PSS_2048_SHA256`, `RSA_PSS_3072_SHA256`, `RSA_PSS_4096_SHA256`, `RSA_PKCS1_2048_SHA256`,
    `RSA_PKCS1_3072_SHA256`, `RSA_PKCS1_4096_SHA256`, `EC_P256_SHA256`, `EC_P384_SHA384`.
    EOT
  }
}

variable "ca_pool_config" {
  description = "The CA pool config. If you pass ca_pool_id, an existing pool is used."
  type = object({
    ca_pool_id = optional(string, null)
    name       = optional(string, null)
    tier       = optional(string, "DEVOPS")
  })
  validation {
    condition = (
      var.ca_pool_config.ca_pool_id != null ||
      var.ca_pool_config.name != null
    )
    error_message = "Tier can only be `DEVOPS` or `ENTERPRISE`."
  }
  validation {
    condition = (
      var.ca_pool_config.tier == "DEVOPS" ||
      var.ca_pool_config.tier == "ENTERPRISE"
    )
    error_message = "Tier can only be `DEVOPS` or `ENTERPRISE`."
  }
  nullable = false
}

variable "location" {
  description = "The location of the CAs."
  type        = string
}

variable "project_id" {
  description = "Project id."
  type        = string
}
