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

variable "cloudrun_svcname" {
  description = "Name of the Cloud Run service."
  type        = string
  default     = "hello-kong"
}

variable "created_resources" {
  description = "IDs of the resources created by autopilot cluster to be consumed here."
  type = object({
    vpc_id    = string
    subnet_id = string
  })
  nullable = false
}

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

variable "namespace" {
  description = "Namespace used for Kong cluster resources."
  type        = string
  nullable    = false
  default     = "kong"
}

variable "prefix" {
  description = "Prefix used for project names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "project_id" {
  description = "Host project with autopilot cluster."
  type        = string
}

variable "region" {
  description = "Cloud region where resources will be deployed."
  type        = string
  default     = "europe-west1"
}

variable "service_project" {
  description = "Service project for Cloud Run service."
  type = object({
    billing_account_id = optional(string)
    parent             = optional(string)
    project_id         = optional(string)
  })
  nullable = false
  validation {
    condition     = var.service_project.billing_account_id != null || var.service_project.project_id != null
    error_message = "At least one of billing_account_id or project_id should be set."
  }
}

variable "templates_path" {
  description = "Path where manifest templates will be read from. Set to null to use the default manifests."
  type        = string
  default     = null
}
