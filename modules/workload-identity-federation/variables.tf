/**
 * Copyright 2025 Google LLC
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

variable "project_id" {
  description = "Project used for resources."
  type        = string
}

variable "pool_name" {
  description = "Workload Identity Pool name."
  type        = string
}

variable "pool_display_name" {
  description = "Workload Identity Pool display name."
  type        = string
  default     = null
}

variable "pool_description" {
  description = "Workload Identity Pool description."
  type        = string
  default     = null
}

variable "pool_disabled" {
  description = "Workload Identity Pool status."
  type        = bool
  default     = false
}

variable "provider_name" {
  description = "Workload Identity Provider name."
  type        = string
}

variable "provider_display_name" {
  description = "Workload Identity Provider display name."
  type        = string
  default     = null
}

variable "provider_description" {
  description = "Workload Identity Provider description."
  type        = string
  default     = null
}

variable "provider_disabled" {
  description = "Workload Identity Provider status."
  type        = bool
  default     = false
}

variable "aws_idp_account_id" {
  description = "Workload Identity Provider AWS Account id."
  type        = string
  default     = null
}

variable "saml_idp_metadata_xml" {
  description = "Workload Identity Provider SAML Metadata XML."
  type        = string
  default     = null
}

variable "x509_pem_certificate_path" {
  description = "Workload Identity Provider X509 PEM Certificate path."
  type        = string
  default     = null
}

variable "oidc" {
  description = "Workload Identity Provider OIDC IdP."
  type = object({
    issuer_uri        = string
    allowed_audiences = optional(list(string))
    jwks_json         = optional(string)
  })
  default = null
}

variable "attribute_mapping" {
  description = "List of attributes"
  type        = map(string)
  validation {
    condition     = contains(keys(var.attribute_mapping), "google.subject")
    error_message = "If attribute_mapping is set, it must contain a key named 'google.subject'."
  }
  nullable = false
  default = {
    "google.subject" = "assertion.sub"
  }
}

variable "attribute_condition" {
  description = "Workload Identity Provider Attribute condition."
  type        = string
  default     = null
}

variable "sa_iam_bindings_additive" {
  description = "List of GCP SA Identities to grant iam.workloadIdentityUser and optionally iam.serviceAccountTokenCreator."
  type = map(object({
    allow_impersonification = bool
    principal_set_suffix    = string
  }))
  nullable = false
  default  = {}
}