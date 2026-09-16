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
    subnetwork      = string
    vpc_self_link   = string
  })
  default = {
    # the load balancer VIP is reserved here and both forwarding rules pin to it
    subnetwork    = "projects/ldj-dev-net-spoke-0/regions/europe-west4/subnetworks/gce"
    vpc_self_link = "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
}

# the project factory writes this at the top level of the instance project's
# tfvars, so the name is theirs and cannot be made more descriptive here. No
# default: the number is the one value that must not be allowed to go stale,
# and the symlinked tfvars always carries it
variable "number" {
  description = "Number of the instance project, from the project factory tfvars."
  type        = number
}

variable "prefix" {
  type    = string
  default = "test-0"
}

variable "projects_config" {
  type = object({
    build = optional(object({
      project_id = string
      number     = optional(number)
    }))
    ssm = object({
      number     = number
      project_id = string
    })
  })
  default = {
    build = {
      project_id = "tf-playground-dev-build-pool-0"
    }
    ssm = {
      number     = 169822929449
      project_id = "tf-playground-dev-build-ssm-0"
    }
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
    ca_pool_id      = "projects/ldj-dev-sec-core/locations/europe-west4/caPools/dev-ca-3"
    deletion_policy = "DELETE"
    custom_host_config = {
      api      = "api.ssm.gcp.qix.it"
      git_http = "git.ssm.gcp.qix.it"
      git_ssh  = "ssh.ssm.gcp.qix.it"
      html     = "ssm.gcp.qix.it"
    }
    # these name the projects that will OWN a consumer NEG or endpoint, not the
    # host projects of their networks: an unlisted project sits at PENDING
    # forever and reports nothing. The intended design is one chain per VPC
    # project, so these are those projects; the single chain this template
    # builds lives in the instance project, allowed implicitly. Immutable, so
    # it cannot be corrected. dr is out for another reason: another perimeter
    psc_allowed_projects = [
      "ldj-dev-net-spoke-0",
      "ldj-prod-net-landing-0",
      "ldj-prod-net-spoke-0"
    ]
  }
}
