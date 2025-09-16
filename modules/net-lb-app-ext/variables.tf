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

variable "backend_buckets_config" {
  description = "Backend buckets configuration."
  type = map(object({
    bucket_name             = string
    compression_mode        = optional(string)
    custom_response_headers = optional(list(string))
    description             = optional(string)
    edge_security_policy    = optional(string)
    enable_cdn              = optional(bool)
    project_id              = optional(string)
    cdn_policy = optional(object({
      bypass_cache_on_request_headers = optional(list(string))
      cache_mode                      = optional(string)
      client_ttl                      = optional(number)
      default_ttl                     = optional(number)
      max_ttl                         = optional(number)
      negative_caching                = optional(bool)
      request_coalescing              = optional(bool)
      serve_while_stale               = optional(number)
      signed_url_cache_max_age_sec    = optional(number)
      cache_key_policy = optional(object({
        include_http_headers   = optional(list(string))
        query_string_whitelist = optional(list(string))
      }))
      negative_caching_policy = optional(object({
        code = optional(number)
        ttl  = optional(number)
      }))
    }))
  }))
  default  = {}
  nullable = true
}

variable "description" {
  description = "Optional description used for resources."
  type        = string
  default     = "Terraform managed."
}

variable "forwarding_rules_config" {
  description = "The optional forwarding rules configuration."
  type = map(object({
    address     = optional(string)
    description = optional(string, "Terraform managed.")
    ipv6        = optional(bool, false)
    name        = optional(string)
    ports       = optional(list(number), null)
  }))
  default = {
    "" = {}
  }
  validation {
    condition = alltrue([
      for k, v in var.forwarding_rules_config :
      v.ports == null || (length(coalesce(v.ports, [])) <= 1)
    ])
    error_message = "Application Load Balancer supports at most one port per forwarding rule."
  }
}

variable "group_configs" {
  description = "Optional unmanaged groups to create. Can be referenced in backends via key or outputs."
  type = map(object({
    zone        = string
    instances   = optional(list(string))
    named_ports = optional(map(number), {})
    project_id  = optional(string)
  }))
  default  = {}
  nullable = false
}

variable "http_proxy_config" {
  description = "HTTP proxy configuration. Only used for non-classic load balancers."
  type = object({
    name                   = optional(string)
    description            = optional(string, "Terraform managed.")
    http_keepalive_timeout = optional(string)
  })
  default  = {}
  nullable = false
}

variable "https_proxy_config" {
  description = "HTTPS proxy connfiguration."
  type = object({
    name                             = optional(string)
    description                      = optional(string, "Terraform managed.")
    certificate_manager_certificates = optional(list(string))
    certificate_map                  = optional(string)
    http_keepalive_timeout           = optional(string)
    quic_override                    = optional(string)
    ssl_policy                       = optional(string)
    mtls_policy                      = optional(string) # id of the mTLS policy to use for the target proxy.
  })
  default  = {}
  nullable = false
}

variable "labels" {
  description = "Labels set on resources."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Load balancer name."
  type        = string
}

variable "neg_configs" {
  description = "Optional network endpoint groups to create. Can be referenced in backends via key or outputs."
  type = map(object({
    project_id  = optional(string)
    description = optional(string)
    cloudfunction = optional(object({
      region          = string
      target_function = optional(string)
      target_urlmask  = optional(string)
    }))
    cloudrun = optional(object({
      region = string
      target_service = optional(object({
        name = string
        tag  = optional(string)
      }))
      target_urlmask = optional(string)
    }))
    serverless_deployment = optional(object({
      region   = string
      platform = string
      resource = optional(string)
      version  = optional(string)
      url_mask = optional(string)
    }))
    gce = optional(object({
      network    = string
      subnetwork = string
      zone       = string
      # default_port = optional(number)
      endpoints = optional(map(object({
        instance   = string
        ip_address = string
        port       = number
      })))
    }))
    hybrid = optional(object({
      network = string
      zone    = string
      # re-enable once provider properly support this
      # default_port = optional(number)
      endpoints = optional(map(object({
        ip_address = string
        port       = number
      })))
    }))
    internet = optional(object({
      use_fqdn = optional(bool, true)
      # re-enable once provider properly support this
      # default_port = optional(number)
      endpoints = optional(map(object({
        destination = string
        port        = number
      })))
    }))
    psc = optional(object({
      region         = string
      target_service = string
      network        = optional(string)
      subnetwork     = optional(string)
    }))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.neg_configs : (
        (try(v.cloudfunction, null) == null ? 0 : 1) +
        (try(v.cloudrun, null) == null ? 0 : 1) +
        (try(v.serverless_deployment, null) == null ? 0 : 1) +
        (try(v.gce, null) == null ? 0 : 1) +
        (try(v.hybrid, null) == null ? 0 : 1) +
        (try(v.internet, null) == null ? 0 : 1) +
        (try(v.psc, null) == null ? 0 : 1) == 1
      )
    ])
    error_message = "Only one type of NEG can be configured at a time."
  }
  validation {
    condition = alltrue([
      for k, v in var.neg_configs : (
        v.cloudrun == null
        ? true
        : v.cloudrun.target_urlmask != null || v.cloudrun.target_service != null
      )
    ])
    error_message = "Cloud Run NEGs need either target service or target urlmask defined."
  }
  validation {
    condition = alltrue([
      for k, v in var.neg_configs : (
        v.cloudfunction == null
        ? true
        : v.cloudfunction.target_urlmask != null || v.cloudfunction.target_function != null
      )
    ])
    error_message = "Cloud Function NEGs need either target function or target urlmask defined."
  }
  validation {
    condition = alltrue([
      for k, v in var.neg_configs : (
        v.serverless_deployment == null
        ? true
        : v.serverless_deployment.url_mask != null || v.serverless_deployment.resource != null
      )
    ])
    error_message = "Serverless deployment NEGs need either resource or url_mask defined."
  }
}

variable "project_id" {
  description = "Project id."
  type        = string
}

variable "protocol" {
  description = "Protocol supported by this load balancer."
  type        = string
  default     = "HTTP"
  nullable    = false
  validation {
    condition = (
      var.protocol == null || var.protocol == "HTTP" || var.protocol == "HTTPS"
    )
    error_message = "Protocol must be HTTP or HTTPS"
  }
}

variable "ssl_certificates" {
  description = "SSL target proxy certificates (only if protocol is HTTPS) for existing, custom, and managed certificates."
  type = object({
    certificate_ids = optional(list(string), [])
    create_configs = optional(map(object({
      certificate = string
      private_key = string
    })), {})
    managed_configs = optional(map(object({
      name        = optional(string)
      domains     = list(string)
      description = optional(string)
    })), {})
  })
  default  = {}
  nullable = false
}

variable "use_classic_version" {
  description = "Use classic Global Load Balancer."
  type        = bool
  default     = true
}
