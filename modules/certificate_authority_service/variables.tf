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
    deletion_protection = optional(string, true)
    type                = optional(string, "SELF_SIGNED")
    is_ca               = optional(bool, true)
    lifetime            = optional(string, null)
    key_spec_algorithm  = optional(string, "RSA_PKCS1_2048_SHA256")
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
      key_agreement      = optional(bool, false)
      key_encipherment   = optional(bool, true)
      server_auth        = optional(bool, true)
      time_stamping      = optional(bool, false)
    }), {})
    subject = optional(object({
      organization = string
      common_name  = string
      }), {
      common_name  = "test.example.com"
      organization = "Test Example"
    })
  }))
  nullable = false
  default = {
    test-ca = {}
  }
}

variable "ca_pool_config" {
  description = "The CA pool config."
  type = object({
    ca_pool_id = optional(string, null)
    name       = optional(string, "test-ca-pool")
    tier       = optional(string, "DEVOPS")
  })
  validation {
    condition = (
      var.ca_pool_config.tier == "DEVOPS" ||
      var.ca_pool_config.tier == "ENTERPRISE"
    )
    error_message = "Tier can only be `DEVOPS` or `ENTERPRISE`."
  }
  nullable = false
  default  = {}
}

variable "location" {
  description = "The location of the CAs."
  type        = string
  default     = "europe-west1"
}

variable "project_id" {
  description = "Project id."
  type        = string
}
