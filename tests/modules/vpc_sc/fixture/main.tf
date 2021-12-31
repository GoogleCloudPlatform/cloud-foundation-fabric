/**
 * Copyright 2021 Google LLC
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

variable "access_policy" {
  description = "Access Policy name, leave null to use auto-created one."
  type        = string
  default     = null
}

variable "access_policy_create" {
  description = "Access Policy configuration, fill in to create. Parent is in 'organizations/123456' format."
  type = object({
    parent = string
    title  = string
  })
  default = {
    parent = "organizations/123456"
    title  = "vpcsc-policy"
  }
}

module "test" {
  source               = "../../../../modules/vpc-sc"
  access_policy        = var.access_policy
  access_policy_create = var.access_policy_create
  access_levels = {
    a1 = {
      combining_function = null
      conditions = [
        {
          device_policy          = null
          ip_subnetworks         = null
          members                = ["user:ludomagno@google.com"]
          negate                 = null
          regions                = null
          required_access_levels = null
        }
      ]
    }
    a2 = {
      combining_function = "OR"
      conditions = [
        {
          device_policy          = null
          ip_subnetworks         = null
          members                = null
          negate                 = null
          regions                = ["IT", "FR"]
          required_access_levels = null
        },
        {
          device_policy          = null
          ip_subnetworks         = null
          members                = null
          negate                 = null
          regions                = ["US"]
          required_access_levels = null
        }
      ]
    }
  }
  service_perimeters_bridge = {
    b1 = {
      status_resources          = ["projects/111110", "projects/111111"]
      spec_resources            = null
      use_explicit_dry_run_spec = false
    }
    b2 = {
      status_resources          = ["projects/111110", "projects/222220"]
      spec_resources            = ["projects/111110", "projects/222220"]
      use_explicit_dry_run_spec = true
    }
  }
  service_perimeters_regular = {
    r1 = {
      spec = null
      status = {
        access_levels       = [module.test.access_level_names["a1"]]
        resources           = ["projects/11111", "projects/111111"]
        restricted_services = ["storage.googleapis.com"]
        egress_policies     = null
        ingress_policies    = null
        vpc_accessible_services = {
          allowed_services   = ["compute.googleapis.com"]
          enable_restriction = true
        }
      }
      use_explicit_dry_run_spec = false
    }
    r2 = {
      spec = null
      status = {
        access_levels       = [module.test.access_level_names["a1"]]
        resources           = ["projects/222220", "projects/222221"]
        restricted_services = ["storage.googleapis.com"]
        egress_policies = [
          {
            egress_from = {
              identity_type = null
              identities    = ["user:foo@example.com"]
            }
            egress_to = {
              operations = null
              resources  = ["projects/333330"]
            }
          }
        ]
        ingress_policies = [
          {
            ingress_from = {
              identity_type        = null
              identities           = null
              source_access_levels = [module.test.access_level_names["a2"]]
              source_resources     = ["projects/333330"]
            }
            ingress_to = {
              operations = [{
                method_selectors = null
                service_name     = "compute.googleapis.com"
              }]
              resources = ["projects/222220"]
            }
          }
        ]
        vpc_accessible_services = {
          allowed_services   = ["compute.googleapis.com"]
          enable_restriction = true
        }
      }
      use_explicit_dry_run_spec = false
    }
  }
}
