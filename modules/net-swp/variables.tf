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

variable "certificates" {
  description = "List of certificates to be used for Secure Web Proxy."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "description" {
  description = "Optional description for the created resources."
  type        = string
  default     = "Managed by Terraform."
}

variable "factories_config" {
  description = "Path to folder with YAML resource description data files."
  type = object({
    policy_rules = optional(string)
    url_lists    = optional(string)
  })
  nullable = false
  default  = {}
}

variable "gateway_config" {
  description = "Optional Secure Web Gateway configuration."
  type = object({
    addresses                = optional(list(string), [])
    delete_router_on_destroy = optional(bool, true)
    labels                   = optional(map(string), {})
    next_hop_routing_mode    = optional(bool, false)
    ports                    = optional(list(string), [443])
    scope                    = optional(string)
  })
  nullable = false
}

variable "name" {
  description = "Name of the Secure Web Proxy resource."
  type        = string
}

variable "network" {
  description = "Name of the network the Secure Web Proxy is deployed into."
  type        = string
}

variable "policy_rules" {
  description = "Policy rules definitions. Merged with policy rules defined via the factory."
  type = map(object({
    priority            = number
    allow               = optional(bool, true)
    description         = optional(string)
    enabled             = optional(bool, true)
    application_matcher = optional(string)
    session_matcher     = optional(string)
    tls_inspect         = optional(bool)
    matcher_args = optional(object({
      application = optional(list(string), [])
      session     = optional(list(string), [])
    }), {})
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue(flatten([
      for k, v in var.policy_rules : concat(
        [
          for vv in v.matcher_args.application :
          contains(["secure_tag", "service_account", "url_list"], split(":", vv)[0])
        ],
        [
          for vv in v.matcher_args.session :
          contains(["secure_tag", "service_account", "url_list"], split(":", vv)[0])
        ],
      )
    ]))
    error_message = "Matcher arguments need to use a 'serviceaccount:' 'tag:' or 'url_list:' prefix."
  }
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
  description = "Project id of the project that holds the network."
  type        = string
}

variable "region" {
  description = "Region where resources will be created."
  type        = string
}

variable "service_attachment" {
  description = "PSC service attachment configuration."
  type = object({
    nat_subnets           = list(string)
    automatic_connection  = optional(bool, false)
    consumer_accept_lists = optional(map(string), {})
    consumer_reject_lists = optional(list(string))
    description           = optional(string)
    domain_name           = optional(string)
    enable_proxy_protocol = optional(bool, false)
    reconcile_connections = optional(bool)
  })
  default = null
}

variable "subnetwork" {
  description = "Name of the subnetwork the Secure Web Proxy is deployed into."
  type        = string
}

variable "tls_inspection_config" {
  description = "TLS inspection configuration."
  type = object({
    create_config = optional(object({
      ca_pool               = optional(string, null)
      description           = optional(string, null)
      exclude_public_ca_set = optional(bool, false)
    }), null)
    id = optional(string, null)
  })
  nullable = false
  default  = {}
  validation {
    condition = !(
      var.tls_inspection_config.create_config != null &&
      var.tls_inspection_config.id != null
    )
    error_message = "You can't assign values both to `create.config.ca_pool` and `id`."
  }
}

variable "url_lists" {
  description = "URL lists."
  type = map(object({
    values      = list(string)
    description = optional(string)
  }))
  default = {}
}
