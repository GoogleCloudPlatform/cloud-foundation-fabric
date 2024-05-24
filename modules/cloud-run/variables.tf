
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

variable "container_concurrency" {
  description = "Maximum allowed in-flight (concurrent) requests per container of the revision."
  type        = string
  default     = null
}

variable "containers" {
  description = "Containers in arbitrary key => attributes format."
  type = map(object({
    image   = string
    args    = optional(list(string))
    command = optional(list(string))
    env     = optional(map(string), {})
    env_from_key = optional(map(object({
      key  = string
      name = string
    })), {})
    liveness_probe = optional(object({
      action = object({
        grpc = optional(object({
          port    = optional(number)
          service = optional(string)
        }))
        http_get = optional(object({
          http_headers = optional(map(string), {})
          path         = optional(string)
        }))
      })
      failure_threshold     = optional(number)
      initial_delay_seconds = optional(number)
      period_seconds        = optional(number)
      timeout_seconds       = optional(number)
    }))
    ports = optional(map(object({
      container_port = optional(number)
      name           = optional(string)
      protocol       = optional(string)
    })), {})
    resources = optional(object({
      limits = optional(object({
        cpu    = string
        memory = string
      }))
      requests = optional(object({
        cpu    = string
        memory = string
      }))
    }))
    startup_probe = optional(object({
      action = object({
        grpc = optional(object({
          port    = optional(number)
          service = optional(string)
        }))
        http_get = optional(object({
          http_headers = optional(map(string), {})
          path         = optional(string)
        }))
        tcp_socket = optional(object({
          port = optional(number)
        }))
      })
      failure_threshold     = optional(number)
      initial_delay_seconds = optional(number)
      period_seconds        = optional(number)
      timeout_seconds       = optional(number)
    }))
    volume_mounts = optional(map(string), {})
  }))
  default  = {}
  nullable = false
}

variable "eventarc_triggers" {
  description = "Event arc triggers for different sources."
  type = object({
    audit_log = optional(map(object({
      method  = string
      service = string
    })), {})
    pubsub                 = optional(map(string), {})
    service_account_email  = optional(string)
    service_account_create = optional(bool, false)
  })
  default = {}
  validation {
    condition = (
      var.eventarc_triggers.service_account_email == null && length(var.eventarc_triggers.audit_log) == 0
      ) || (
      var.eventarc_triggers.service_account_email != null
    )
    error_message = "service_account_email is required if providing audit_log"
  }
}

variable "gen2_execution_environment" {
  description = "Use second generation execution environment."
  type        = bool
  default     = false
}

variable "iam" {
  description = "IAM bindings for Cloud Run service in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "ingress_settings" {
  description = "Ingress settings."
  type        = string
  default     = null
  validation {
    condition = contains(
      ["all", "internal", "internal-and-cloud-load-balancing"],
      coalesce(var.ingress_settings, "all")
    )
    error_message = "Ingress settings can be one of 'all', 'internal', 'internal-and-cloud-load-balancing'."
  }
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name used for cloud run service."
  type        = string
}

variable "prefix" {
  description = "Optional prefix used for resource names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "Project id used for all resources."
  type        = string
}

variable "region" {
  description = "Region used for all resources."
  type        = string
}

variable "revision_annotations" {
  description = "Configure revision template annotations."
  type = object({
    autoscaling = optional(object({
      max_scale = number
      min_scale = number
    }))
    cloudsql_instances  = optional(list(string), [])
    vpcaccess_connector = optional(string)
    vpcaccess_egress    = optional(string)
  })
  default  = {}
  nullable = false
}

variable "revision_name" {
  description = "Revision name."
  type        = string
  default     = null
}

variable "service_account" {
  description = "Service account email. Unused if service account is auto-created."
  type        = string
  default     = null
}

variable "service_account_create" {
  description = "Auto-create service account."
  type        = bool
  default     = false
}

variable "startup_cpu_boost" {
  description = "Enable startup cpu boost."
  type        = bool
  default     = false
}

variable "tag_bindings" {
  description = "Tag bindings for this service, in key => tag value id format."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "timeout_seconds" {
  description = "Maximum duration the instance is allowed for responding to a request."
  type        = number
  default     = null
}

variable "traffic" {
  description = "Traffic steering configuration. If revision name is null the latest revision will be used."
  type = map(object({
    percent = number
    latest  = optional(bool)
    tag     = optional(string)
  }))
  default  = {}
  nullable = false
}

variable "volumes" {
  description = "Named volumes in containers in name => attributes format."
  type = map(object({
    secret_name  = string
    default_mode = optional(string)
    items = optional(map(object({
      path = string
      mode = optional(string)
    })))
  }))
  default  = {}
  nullable = false
}

variable "vpc_connector_create" {
  description = "Populate this to create a VPC connector. You can then refer to it in the template annotations."
  type = object({
    ip_cidr_range = optional(string)
    vpc_self_link = optional(string)
    machine_type  = optional(string)
    name          = optional(string)
    instances = optional(object({
      max = optional(number)
      min = optional(number)
    }), {})
    throughput = optional(object({
      max = optional(number)
      min = optional(number)
    }), {})
    subnet = optional(object({
      name       = optional(string)
      project_id = optional(string)
    }), {})
  })
  default = null
}
