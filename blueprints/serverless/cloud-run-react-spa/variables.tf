# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "backend" {
  type = object({
    function_name   = optional(string, "my-react-app-backend")
    service_account = optional(string, "my-react-app-backend")
  })
  description = "Backend settings"
  default     = {}
}

variable "bucket" {
  type = object({
    name          = optional(string, "my-react-app")
    random_suffix = optional(bool, true)
    build_name    = optional(string, "my-react-app-build") # Build bucket for CF v2
  })
  description = "Bucket settings for hosting the SPA"
  default     = {}
}

variable "global_lb" {
  type        = bool
  description = "Deploy a global load balancer"
  default     = true
}

variable "lb_name" {
  type        = string
  description = "Application Load Balancer name"
  default     = "my-react-app"
}

variable "nginx_image" {
  type        = string
  description = "Nginx image to use for regional load balancer"
  default     = "gcr.io/cloud-marketplace/google/nginx1:1.26"
}

variable "project_create" {
  description = "Parameters for the creation of a new project."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "project_id" {
  type        = string
  description = "Google Cloud project ID"
}

variable "region" {
  type        = string
  description = "Region where to deploy the function and resources"
}

variable "regional_lb" {
  type        = bool
  description = "Deploy a regional load balancer"
  default     = false
}

variable "vpc_config" {
  type = object({
    network                = string
    network_project        = optional(string)
    subnetwork             = string
    subnet_cidr            = optional(string, "172.20.20.0/24")
    proxy_only_subnetwork  = string
    proxy_only_subnet_cidr = optional(string, "172.20.30.0/24")
    create                 = optional(bool, true)
  })
  description = "Settings for VPC (required when deploying a Regional XLB)"
  default = {
    network               = "my-react-app-vpc"
    subnetwork            = "my-react-app-vpc-subnet"
    proxy_only_subnetwork = "my-react-app-vpc-proxy-subnet"
  }
}
