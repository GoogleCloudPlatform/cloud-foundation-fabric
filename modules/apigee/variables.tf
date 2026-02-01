/**
 * Copyright 2023 Google LLC
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

variable "addons_config" {
  description = "Addons configuration."
  type = object({
    advanced_api_ops    = optional(bool, false)
    api_security        = optional(bool, false)
    connectors_platform = optional(bool, false)
    integration         = optional(bool, false)
    monetization        = optional(bool, false)
  })
  default = null
}

variable "dns_zones" {
  description = "DNS zones."
  type = map(object({
    domain            = string
    description       = string
    target_project_id = string
    target_network_id = string
  }))
  default  = {}
  nullable = false
}

variable "endpoint_attachments" {
  description = "Endpoint attachments."
  type = map(object({
    region             = string
    service_attachment = string
  }))
  default  = {}
  nullable = false
}

variable "envgroups" {
  description = "Environment groups (NAME => [HOSTNAMES])."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "environments" {
  description = "Environments."
  type = map(object({
    api_proxy_type    = optional(string)
    description       = optional(string, "Terraform-managed")
    display_name      = optional(string)
    deployment_type   = optional(string)
    envgroups         = optional(list(string), [])
    forward_proxy_uri = optional(string)
    iam               = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      role    = string
      members = list(string)
    })), {})
    iam_bindings_additive = optional(map(object({
      role   = string
      member = string
    })), {})
    node_config = optional(object({
      min_node_count = optional(number)
      max_node_count = optional(number)
    }))
    type = optional(string)
  }))
  default  = {}
  nullable = false
}

variable "instances" {
  description = "Instances ([REGION] => [INSTANCE])."
  type = map(object({
    consumer_accept_list          = optional(list(string))
    description                   = optional(string, "Terraform-managed")
    disk_encryption_key           = optional(string)
    display_name                  = optional(string)
    enable_nat                    = optional(bool, false)
    activate_nat                  = optional(bool, false)
    environments                  = optional(list(string), [])
    name                          = optional(string)
    runtime_ip_cidr_range         = optional(string)
    troubleshooting_ip_cidr_range = optional(string)
    access_logging = optional(object({
      enabled = optional(bool, true)
      filter  = optional(string)
    }))
  }))
  validation {
    condition = alltrue([
      for k, v in var.instances :
      # has troubleshooting_ip => has runtime_ip
      v.runtime_ip_cidr_range != null || v.troubleshooting_ip_cidr_range == null
    ])
    error_message = "Using a troubleshooting range requires specifying a runtime range too."
  }
  default  = {}
  nullable = false
}

variable "organization" {
  description = "Apigee organization. If set to null the organization must already exist."
  type = object({
    analytics_region                 = optional(string)
    api_consumer_data_encryption_key = optional(string)
    api_consumer_data_location       = optional(string)
    authorized_network               = optional(string)
    billing_type                     = optional(string)
    control_plane_encryption_key     = optional(string)
    database_encryption_key          = optional(string)
    description                      = optional(string, "Terraform-managed")
    disable_vpc_peering              = optional(bool, false)
    display_name                     = optional(string)
    properties                       = optional(map(string), {})
    runtime_type                     = optional(string, "CLOUD")
    retention                        = optional(string)
  })
  validation {
    condition = var.organization == null || (
      try(var.organization.runtime_type, null) == "CLOUD" || !try(var.organization.disable_vpc_peering, false)
    )
    error_message = "Disabling the VPC peering can only be done in organization using the CLOUD runtime."
  }
  validation {
    condition = var.organization == null || (
      try(var.organization.authorized_network, null) == null || !try(var.organization.disable_vpc_peering, false)
    )
    error_message = "Disabling the VPC peering is mutually exclusive with authorized_network."
  }
  default = null
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "security_profiles" {
  description = "Security profiles configuration (ID => {description, profile_assessment_configs})."
  type = map(object({
    description = optional(string)
    profile_assessment_configs = optional(object({
      sanitize-user-prompt-policy-check     = optional(string, null)
      sanitize-model-response-policy-check  = optional(string, null)
      semantic-cache-lookup-policy-check    = optional(string, null)
      auth-policies-check                   = optional(string, null)
      continue-on-error-auth-policies-check = optional(string, null)
      access-control-policy-check           = optional(string, null)
      basic-auth-policy-check               = optional(string, null)
      hmac-policy-check                     = optional(string, null)
      oauthv2-policy-check                  = optional(string, null)
      validate-saml-assertion-policy-check  = optional(string, null)
      verify-api-key-policy-check           = optional(string, null)
      verify-iam-policy-check               = optional(string, null)
      verify-jws-policy-check               = optional(string, null)
      verify-jwt-policy-check               = optional(string, null)
      cors-policies-check                   = optional(string, null)
      cors-policy-check                     = optional(string, null)
      cors-assignmessage-policy-check       = optional(string, null)
      mediation-policies-check              = optional(string, null)
      soap-validation-policy-check          = optional(string, null)
      oas-validation-policy-check           = optional(string, null)
      tls-target-server-check               = optional(string, null)
      mtls-target-server-check              = optional(string, null)
      target-enforce-field-check            = optional(string, null)
      threat-policies-check                 = optional(string, null)
      continue-on-error-threat-policies     = optional(string, null)
      json-threat-protection-policy-check   = optional(string, null)
      regex-protection-policy-check         = optional(string, null)
      xml-threat-protection-policy-check    = optional(string, null)
      traffic-management-policies-check     = optional(string, null)
      lookup-cache-policy-check             = optional(string, null)
      quota-policy-check                    = optional(string, null)
      response-cache-policy-check           = optional(string, null)
      spike-arrest-policy-check             = optional(string, null)
    }), {})
  }))
  default  = {}
  nullable = false
}

