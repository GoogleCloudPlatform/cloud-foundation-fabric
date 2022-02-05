/**
 * Copyright 2022 Google LLC
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

variable "billing_account_id" {
  # tfdoc:variable:source bootstrap
  description = "Billing account id."
  type        = string
}

variable "folder_id" {
  # tfdoc:variable:source resman
  description = "Folder to be used for the networking resources in folders/nnnn format."
  type        = string
}

variable "groups" {
  # tfdoc:variable:source bootstrap
  description = "Group names to grant organization-level permissions."
  type        = map(string)
  # https://cloud.google.com/docs/enterprise/setup-checklist
  default = {
    gcp-billing-admins      = "gcp-billing-admins",
    gcp-devops              = "gcp-devops",
    gcp-network-admins      = "gcp-network-admins"
    gcp-organization-admins = "gcp-organization-admins"
    gcp-security-admins     = "gcp-security-admins"
    gcp-support             = "gcp-support"
  }
}

variable "kms_defaults" {
  description = "Defaults used for KMS keys."
  type = object({
    locations       = list(string)
    rotation_period = string
  })
  default = {
    locations       = ["europe", "europe-west1", "europe-west3", "global"]
    rotation_period = "7776000s"
  }
}

variable "kms_keys" {
  description = "KMS keys to create, keyed by name. Null attributes will be interpolated with defaults."
  type = map(object({
    iam             = map(list(string))
    labels          = map(string)
    locations       = list(string)
    rotation_period = string
  }))
  default = {}
}

variable "kms_restricted_admins" {
  description = "Map of environment => [identities] who can assign the encrypt/decrypt roles on keys."
  type        = map(list(string))
  default     = {}
}

variable "organization" {
  # tfdoc:variable:source bootstrap
  description = "Organization details."
  type = object({
    domain      = string
    id          = number
    customer_id = string
  })
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
}

variable "vpc_sc_access_levels" {
  description = "VPC SC access level definitions."
  type = map(object({
    combining_function = string
    conditions = list(object({
      ip_subnetworks         = list(string)
      members                = list(string)
      negate                 = bool
      regions                = list(string)
      required_access_levels = list(string)
    }))
  }))
  default = {}
}

variable "vpc_sc_egress_policies" {
  description = "VPC SC egress policy defnitions."
  type = map(object({
    egress_from = object({
      identity_type = string
      identities    = list(string)
    })
    egress_to = object({
      operations = list(object({
        method_selectors = list(string)
        service_name     = string
      }))
      resources = list(string)
    })
  }))
  default = {}
}

variable "vpc_sc_ingress_policies" {
  description = "VPC SC ingress policy defnitions."
  type = map(object({
    ingress_from = object({
      identity_type        = string
      identities           = list(string)
      source_access_levels = list(string)
      source_resources     = list(string)
    })
    ingress_to = object({
      operations = list(object({
        method_selectors = list(string)
        service_name     = string
      }))
      resources = list(string)
    })
  }))
  default = {}
}

variable "vpc_sc_perimeter_access_levels" {
  description = "VPC SC perimeter access_levels."
  type = object({
    dev     = list(string)
    landing = list(string)
    prod    = list(string)
  })
  default = null
}

variable "vpc_sc_perimeter_egress_policies" {
  description = "VPC SC egress policies per perimeter, values reference keys defined in the `vpc_sc_ingress_policies` variable."
  type = object({
    dev     = list(string)
    landing = list(string)
    prod    = list(string)
  })
  default = null
}

variable "vpc_sc_perimeter_ingress_policies" {
  description = "VPC SC ingress policies per perimeter, values reference keys defined in the `vpc_sc_ingress_policies` variable."
  type = object({
    dev     = list(string)
    landing = list(string)
    prod    = list(string)
  })
  default = null
}

#TODO Ask Team
variable "vpc_sc_dataplatform_projects" {
  description = "VPC SC perimeter resources."
  type = object({
    dev  = list(string)
    prod = list(string)
  })
  default = null
}

#TODO Ask Team
variable "vpc_sc_dataplatform_folders" {
  description = "VPC SC perimeter resources."
  type = object({
    dev  = list(string)
    prod = list(string)
  })
  default = null
}

variable "vpc_sc_perimeter_projects" {
  description = "VPC SC perimeter resources."
  type = object({
    dev     = list(string)
    landing = list(string)
    prod    = list(string)
  })
  default = null
}
