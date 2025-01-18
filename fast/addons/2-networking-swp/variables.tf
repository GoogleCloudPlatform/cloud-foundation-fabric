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

variable "certificate_authority" {
  description = "Optional Certificate Authority Service pool and CA used by SWP."
  type = object({
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
  })
  nullable = false
}

variable "enable_services" {
  description = "Configure project by enabling services required for this add-on."
  type        = bool
  nullable    = false
  default     = false
}

variable "factories_config" {
  description = "SWP factories configuration paths. Keys in the `swp_configs` variable will be appended to derive individual SWP factory paths."
  type = object({
    policy_rules = optional(string, "data/policy-rules")
    url_lists    = optional(string, "data/url-lists")
  })
  nullable = false
  default  = {}
}

variable "locations" {
  description = "Regions where the resources will be created. Keys are used as short names appended to resource names. Interpolation with FAST region names is supported."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "name" {
  description = "Name used for resource names."
  type        = string
  nullable    = false
  default     = "swp"
}

variable "outputs_location" {
  description = "Path where providers and tfvars files for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "policy_rules_contexts" {
  description = "Replacement contexts for policy rules matcher arguments."
  type = object({
    secure_tags      = optional(map(string), {})
    service_accounts = optional(map(string), {})
    url_lists        = optional(map(string), {})
  })
  nullable = false
  default  = {}
}

variable "project_id" {
  description = "Project where the resources will be created."
  type        = string
  nullable    = false
}

variable "swp_configs" {
  description = "Secure Web Proxy configuration, one per region."
  type = map(object({
    network_id               = string
    subnetwork_id            = string
    certificates             = optional(list(string), [])
    tls_inspection_policy_id = optional(string, null)
    gateway_config = optional(object({
      addresses                = optional(list(string), [])
      delete_router_on_destroy = optional(bool, true)
      labels                   = optional(map(string), {})
      next_hop_routing_mode    = optional(bool, false)
      ports                    = optional(list(string), [443])
      scope                    = optional(string)
    }), {})
    service_attachment = optional(object({
      nat_subnets           = list(string)
      automatic_connection  = optional(bool, false)
      consumer_accept_lists = optional(map(string), {})
      consumer_reject_lists = optional(list(string))
      description           = optional(string)
      domain_name           = optional(string)
      enable_proxy_protocol = optional(bool, false)
      reconcile_connections = optional(bool)
    }))
  }))
  nullable = false
  default  = {}
}

variable "tls_inspection_policy" {
  description = "TLS inspection policy configuration. If a CA pool is not specified a local one must be created via the `certificate_authority` variable."
  type = object({
    ca_pool_id            = optional(string)
    exclude_public_ca_set = optional(bool)
    tls = optional(object({
      custom_features = optional(list(string))
      feature_profile = optional(string)
      min_version     = optional(string)
    }))
  })
  default = null
  validation {
    condition = (
      var.tls_inspection_policy == null ||
      (
        try(var.tls_inspection_policy.ca_pool_id, null) != null ||
        var.certificate_authority != null
      )
    )
    error_message = "Either specify a CA pool or create one via the certification_authority variable."
  }
  validation {
    condition = (
      try(var.tls_inspection_policy.tls, null) == null ||
      contains(
        ["TLS_VERSION_UNSPECIFIED", "TLS_1_0", "TLS_1_1", "TLS_1_2", "TLS_1_3", "-"],
        try(var.tls_inspection_policy.tls.min_version, "-")
      )
    )
    error_message = "Invalid min TLS version."
  }
  validation {
    condition = (
      try(var.tls_inspection_policy.tls, null) == null ||
      contains(
        [
          "PROFILE_UNSPECIFIED", "PROFILE_COMPATIBLE", "PROFILE_MODERN",
          "PROFILE_RESTRICTED", "PROFILE_CUSTOM"
        ],
        try(var.tls_inspection_policy.tls.feature_profile, "-")
      )
    )
    error_message = "Invalid TLS version feature profile."
  }
  validation {
    condition = (
      try(var.tls_inspection_policy.tls.custom_features, null) == null ||
      try(var.tls_inspection_policy.tls.feature_profile, null) == "PROFILE_CUSTOM"
    )
    error_message = "TLS custom features can only be used with custom profile."
  }
}
