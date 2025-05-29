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

variable "access_levels" {
  description = "Access level definitions."
  type = map(object({
    combining_function = optional(string)
    conditions = optional(list(object({
      device_policy = optional(object({
        allowed_device_management_levels = optional(list(string))
        allowed_encryption_statuses      = optional(list(string))
        require_admin_approval           = bool
        require_corp_owned               = bool
        require_screen_lock              = optional(bool)
        os_constraints = optional(list(object({
          os_type                    = string
          minimum_version            = optional(string)
          require_verified_chrome_os = optional(bool)
        })))
      }))
      ip_subnetworks         = optional(list(string), [])
      members                = optional(list(string), [])
      negate                 = optional(bool)
      regions                = optional(list(string), [])
      required_access_levels = optional(list(string), [])
      vpc_subnets            = optional(map(list(string)), {})
    })), [])
    description = optional(string)
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.access_levels : (
        v.combining_function == null ||
        v.combining_function == "AND" ||
        v.combining_function == "OR"
      )
    ])
    error_message = "Invalid `combining_function` value (null, \"AND\", \"OR\" accepted)."
  }
  validation {
    condition = alltrue([
      for k, v in var.access_levels : alltrue([
        for condition in v.conditions : alltrue([
          for member in condition.members : can(regex("^(?:serviceAccount:|user:)", member))
        ])
      ])
    ])
    error_message = "Invalid `conditions[].members`. It needs to start with on of the prefixes: 'serviceAccount:' or 'user:'."
  }
}

variable "access_policy" {
  description = "Access policy id (used for tenant-level VPC-SC configurations)."
  type        = number
  default     = null
}

variable "egress_policies" {
  description = "Egress policy definitions that can be referenced in perimeters."
  type = map(object({
    title = optional(string)
    from = object({
      access_levels = optional(list(string), [])
      identity_type = optional(string)
      identities    = optional(list(string))
      resources     = optional(list(string), [])
    })
    to = object({
      external_resources = optional(list(string))
      operations = optional(list(object({
        method_selectors     = optional(list(string))
        permission_selectors = optional(list(string))
        service_name         = string
      })), [])
      resources = optional(list(string))
      roles     = optional(list(string))
    })
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.egress_policies :
      v.from.identity_type == null ? true : contains([
        "IDENTITY_TYPE_UNSPECIFIED", "ANY_IDENTITY",
        "ANY_USER_ACCOUNT", "ANY_SERVICE_ACCOUNT", ""
      ], v.from.identity_type)
    ])
    error_message = "Invalid `from.identity_type` value in egress policy."
  }
  validation {
    condition = alltrue([
      for k, v in var.egress_policies : v.from.identities == null ? true : alltrue([
        for identity in v.from.identities : can(regex("^(?:serviceAccount:|user:|group:|principal:|principalSet:)", identity))
      ])
    ])
    error_message = "Invalid `from.identity`. It needs to start with on of the prefixes: 'serviceAccount:', 'user:', 'group:', 'principal:' or 'principalSet:."
  }
}

variable "factories_config" {
  description = "Paths to folders that enable factory functionality."
  type = object({
    access_levels       = optional(string, "data/access-levels")
    egress_policies     = optional(string, "data/egress-policies")
    ingress_policies    = optional(string, "data/ingress-policies")
    perimeters          = optional(string, "data/perimeters")
    restricted_services = optional(string, "data/restricted-services.yaml")
    context = optional(object({
      identity_sets = optional(map(list(string)), {})
      resource_sets = optional(map(list(string)), {})
      service_sets  = optional(map(list(string)), {})
    }), {})
  })
  nullable = false
  default  = {}
}

variable "ingress_policies" {
  description = "Ingress policy definitions that can be referenced in perimeters."
  type = map(object({
    title = optional(string)
    from = object({
      access_levels = optional(list(string), [])
      identity_type = optional(string)
      identities    = optional(list(string))
      resources     = optional(list(string), [])
    })
    to = object({
      operations = optional(list(object({
        method_selectors     = optional(list(string))
        permission_selectors = optional(list(string))
        service_name         = string
      })), [])
      resources = optional(list(string))
      roles     = optional(list(string))
    })
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.ingress_policies :
      v.from.identity_type == null ? true : contains([
        "IDENTITY_TYPE_UNSPECIFIED", "ANY_IDENTITY",
        "ANY_USER_ACCOUNT", "ANY_SERVICE_ACCOUNT", ""
      ], v.from.identity_type)
    ])
    error_message = "Invalid `from.identity_type` value in ingress policy."
  }
  validation {
    condition = alltrue([
      for k, v in var.ingress_policies : v.from.identities == null ? true : alltrue([
        for identity in v.from.identities : can(regex("^(?:serviceAccount:|user:|group:|principal:|principalSet:)", identity))
      ])
    ])
    error_message = "Invalid `from.identity`. It needs to start with on of the prefixes: 'serviceAccount:', 'user:', 'group:', 'principal:', 'principalSet:'."
  }
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "perimeters" {
  description = "Perimeter definitions."
  type = map(object({
    description               = optional(string)
    ignore_resource_changes   = optional(bool, false)
    title                     = optional(string)
    use_explicit_dry_run_spec = optional(bool, false)
    spec = optional(object({
      access_levels       = optional(list(string))
      egress_policies     = optional(list(string))
      ingress_policies    = optional(list(string))
      restricted_services = optional(list(string))
      resources           = optional(list(string))
      vpc_accessible_services = optional(object({
        allowed_services   = list(string)
        enable_restriction = optional(bool, true)
      }))
    }))
    status = optional(object({
      access_levels       = optional(list(string))
      egress_policies     = optional(list(string))
      ingress_policies    = optional(list(string))
      resources           = optional(list(string))
      restricted_services = optional(list(string))
      vpc_accessible_services = optional(object({
        allowed_services   = list(string)
        enable_restriction = optional(bool, true)
      }))
    }))
  }))
  nullable = false
  default  = {}
}

variable "resource_discovery" {
  description = "Automatic discovery of perimeter projects."
  type = object({
    enabled          = optional(bool, true)
    ignore_folders   = optional(list(string), [])
    ignore_projects  = optional(list(string), [])
    include_projects = optional(list(string), [])
  })
  nullable = false
  default  = {}
}
