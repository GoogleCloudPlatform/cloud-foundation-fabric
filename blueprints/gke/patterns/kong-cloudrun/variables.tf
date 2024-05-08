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

variable "credentials_config" {
  description = "Configure how Terraform authenticates to the cluster."
  type = object({
    fleet_host = optional(string)
    kubeconfig = optional(object({
      context = optional(string)
      path    = optional(string, "~/.kube/config")
    }))
  })
  nullable = false
  validation {
    condition = (
      (var.credentials_config.fleet_host != null) !=
      (var.credentials_config.kubeconfig != null)
    )
    error_message = "Exactly one of fleet host or kubeconfig must be set."
  }
}

variable "namespace" {
  description = "Namespace used for Kong cluster resources."
  type        = string
  nullable    = false
  default     = "kong"
}

/* variable "image" {
  description = "Container image to use."
  type        = string
  nullable    = false
  default     = "redis:6.2"
}

variable "statefulset_config" {
  description = "Configure Redis cluster statefulset parameters."
  type = object({
    replicas = optional(number, 6)
    resource_requests = optional(object({
      cpu    = optional(string, "1")
      memory = optional(string, "1Gi")
    }), {})
    volume_claim_size = optional(string, "10Gi")
  })
  nullable = false
  default  = {}
  validation {
    condition     = var.statefulset_config.replicas >= 6
    error_message = "The minimum number of Redis cluster replicas is 6."
  }
} */

variable "templates_path" {
  description = "Path where manifest templates will be read from. Set to null to use the default manifests."
  type        = string
  default     = null
}

variable "created_resources" {
  description = "Names of the resources created by autopilot cluster to be consumed here."
  type = object({
    vpc_name    = string
    subnet_name = string
  })
  default = {
    vpc_name    = "autopilot"
    subnet_name = "cluster-default"
  }
  nullable = false
}

variable "custom_domain" {
  description = "Custom domain for the Load Balancer."
  type        = string
  default     = "acme.org"
}

variable "image" {
  description = "Container image for Cloud Run services."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "prefix" {
  description = "Prefix used for project names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "project_configs" {
  description = "Service projects for Cloud Run services."
  type = map(object({
    billing_account_id = optional(string)
    parent             = optional(string)
    project_id         = optional(string)
  }))
  default = {
    service-project-1 = {}
    service-project-2 = {}
  }
  nullable = false
}

variable "project_id" {
  description = "Host project with (autopilot) cluster (without prefix)."
  type        = string
}

variable "region" {
  description = "Cloud region where resources will be deployed."
  type        = string
  default     = "europe-west1"
}
