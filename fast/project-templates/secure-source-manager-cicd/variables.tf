/**
 * Copyright 2026 Google LLC
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


variable "locations" {
  type = object({
    build = string
    ssm   = string
  })
  default = {
    build = "europe-west8"
    ssm   = "europe-west4"
  }
}

variable "network_config" {
  type = object({
    build_psa_range = optional(string, "/26")
    vpc_self_link   = string
  })
  default = {
    vpc_self_link = "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
}

variable "prefix" {
  type    = string
  default = "test-0"
}

variable "project_ids" {
  type = object({
    build = string
    ssm   = string
  })
  default = {
    build = "tf-playground-dev-build-pool-0"
    ssm   = "tf-playground-dev-build-ssm-0"
  }
}

variable "ssm_config" {
  type = object({
    ca_pool_id      = string
    deletion_policy = optional(string, null)
    custom_host_config = object({
      api      = string
      git_http = string
      git_ssh  = string
      html     = string
    })
    psc_allowed_projects = optional(list(string))
  })
  default = {
    ca_pool_id      = "projects/ldj-dev-sec-core/locations/europe-west8/caPools/dev-ca-0"
    deletion_policy = "DELETE"
    custom_host_config = {
      api      = "api.ssm.gcp.qix.it"
      git_http = "git.ssm.gcp.qix.it"
      git_ssh  = "ssh.ssm.gcp.qix.it"
      html     = "ssm.gcp.qix.it"
    }
    psc_allowed_projects = [
      "ldj-dev-net-spoke-0",
      "ldj-dr-net-spoke-0",
      "ldj-prod-net-landing-0",
      "ldj-prod-net-spoke-0"
    ]
  }
}
