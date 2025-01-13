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

variable "base_name" {
  description = "Base name appended to each swp configuration name to create resource names."
  type        = string
  nullable    = false
  default     = "swp-0"
}

variable "certificate_authorities" {
  description = "Certificate Authority Service pool and CAs created in the add-on project."
  type = map(object({
    location              = string
    project_id            = string
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
      ca_pool_id = optional(string, null)
      name       = optional(string, null)
      tier       = optional(string, "DEVOPS")
    })
  }))
  nullable = false
  default  = {}
}

variable "factories_config" {
  description = "Base paths which are joined to swp config names to derive paths to folders with YAML resource description data files."
  type = object({
    policy_rules_base = optional(string)
    url_lists_base    = optional(string)
  })
  nullable = false
  default  = {}
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

variable "swp_configs" {
  description = "Secure Web Proxy configuration, one per project-region."
  type = map(object({
    project_id    = string
    region        = string
    network_id    = string
    subnetwork_id = string
    certificates  = optional(list(string), [])
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
    tls_inspection_config = optional(object({
      create_config = optional(object({
        ca_pool               = optional(string, null)
        description           = optional(string, null)
        exclude_public_ca_set = optional(bool, false)
      }), null)
      id = optional(string, null)
    }))
  }))
  nullable = false
  default  = {}
}

variable "tls_inspection_policies" {
  description = "TLS inspection policies configuration. CA pools, trust configs and host project ids support interpolation."
  type = map(object({
    ca_pool_id            = string
    exclude_public_ca_set = optional(bool)
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
