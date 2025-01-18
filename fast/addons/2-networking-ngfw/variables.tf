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
  description = "Certificate Authority Service pool and CAs. If host project ids is null identical pools and CAs are created in every host project."
  type = map(object({
    location              = string
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
    ca_pool_config = optional(object({
      create_pool = optional(object({
        name = optional(string)
        tier = optional(string, "DEVOPS")
      }))
      use_pool = optional(object({
        id = string
      }))
    }))
  }))
  nullable = false
  default  = {}
}

variable "enable_services" {
  description = "Configure project by enabling services required for this add-on."
  type        = bool
  nullable    = false
  default     = true
}

variable "names" {
  description = "Configuration for names used for output files."
  type = object({
    output_files_prefix = optional(string, "2-networking-ngfw")
  })
  nullable = false
  default  = {}
}

variable "ngfw_config" {
  description = "Configuration for NGFW Enterprise endpoints. Billing project defaults to the automation project. Network and TLS inspection policy ids support interpolation."
  type = object({
    endpoint_zones = list(string)
    name           = optional(string, "ngfw-0")
    network_associations = optional(map(object({
      vpc_id                = string
      disabled              = optional(bool)
      tls_inspection_policy = optional(string)
      zones                 = optional(list(string))
    })), {})
  })
  nullable = false
}

variable "outputs_location" {
  description = "Path where providers and tfvars files for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Project where the network security resources will be created."
  type        = string
  nullable    = false
}

variable "security_profiles" {
  description = "Security profile groups for Layer 7 inspection. Null environment list means all environments."
  type = map(object({
    description = optional(string)
    threat_prevention_profile = optional(object({
      severity_overrides = optional(map(object({
        action   = string
        severity = string
      })))
      threat_overrides = optional(map(object({
        action    = string
        threat_id = string
      })))
    }), {})
  }))
  nullable = false
  default = {
    ngfw-default = {}
  }
  validation {
    condition = alltrue(flatten([
      for _, v in var.security_profiles : [
        for _, sv in coalesce(v.threat_prevention_profile.severity_overrides, {}) : (
          contains(["ALERT", "ALLOW", "DEFAULT_ACTION", "DENY"], sv.action) &&
          contains(["CRITICAL", "HIGH", "INFORMATIONAL", "LOW", "MEDIUM"], sv.severity)
        )
      ]
    ]))
    error_message = "Incorrect severity override token."
  }
  validation {
    condition = alltrue(flatten([
      for _, v in var.security_profiles : [
        for _, sv in coalesce(v.threat_prevention_profile.threat_overrides, {}) : (
          contains(["ALERT", "ALLOW", "DEFAULT_ACTION", "DENY"], sv.action)
        )
      ]
    ]))
    error_message = "Incorrect threat override token."
  }
}

variable "tls_inspection_policies" {
  description = "TLS inspection policies configuration. CA pools, trust configs and host project ids support interpolation."
  type = map(object({
    ca_pool_id            = string
    location              = string
    exclude_public_ca_set = optional(bool)
    trust_config          = optional(string)
    tls = optional(object({
      custom_features = optional(list(string))
      feature_profile = optional(string)
      min_version     = optional(string)
    }), {})
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.tls_inspection_policies : v.tls.min_version == null || contains(
        ["TLS_VERSION_UNSPECIFIED", "TLS_1_0", "TLS_1_1", "TLS_1_2", "TLS_1_3"],
        coalesce(v.tls.min_version, "-")
      )
    ])
    error_message = "Invalid min TLS version."
  }
  validation {
    condition = alltrue([
      for k, v in var.tls_inspection_policies : v.tls.feature_profile == null || contains(
        ["PROFILE_UNSPECIFIED", "PROFILE_COMPATIBLE", "PROFILE_MODERN", "PROFILE_RESTRICTED", "PROFILE_CUSTOM"],
        coalesce(v.tls.feature_profile, "-")
      )
    ])
    error_message = "Invalid TLS feature profile."
  }
  validation {
    condition = alltrue([
      for k, v in var.tls_inspection_policies :
      v.tls.custom_features == null || v.tls.feature_profile == "PROFILE_CUSTOM"
    ])
    error_message = "TLS custom features can only be used with custom profile."
  }
}

variable "trust_configs" {
  description = "Certificate Manager trust configurations for TLS inspection policies. Project ids and region can reference keys in the relevant FAST variables."
  type = map(object({
    location                 = string
    description              = optional(string)
    allowlisted_certificates = optional(map(string))
    trust_stores = optional(map(object({
      intermediate_cas = optional(map(string))
      trust_anchors    = optional(map(string))
    })))
  }))
  nullable = false
  default = {
    # dev-ngfw-default = {
    #   location   = "primary"
    #   project_id = "dev-spoke-0"
    # }
    # prod-ngfw-default = {
    #   location   = "primary"
    #   project_id = "prod-spoke-0"
    # }
  }
  validation {
    condition = alltrue([
      for k, v in var.trust_configs : (
        v.allowlisted_certificates != null ||
        try(v.trust_stores.intermediate_cas, null) != null ||
        try(v.trust_stores.trust_anchors, null) != null
      )
    ])
    error_message = "a trust configuration needs at least one set of allowlisted certificates, or a valid trust store."
  }
}
