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

variable "clusters" {
  description = "A map of GKE clusters to register with GKE Hub and their associated feature configurations. The key is a logical name for the cluster, and the value is an object describing the cluster and its features."
  type = map(object({
    id                = string
    configmanagement  = optional(string)
    policycontroller  = optional(string)
    servicemesh       = optional(string)
    workload_identity = optional(bool, false)
  }))
  default  = {}
  nullable = false
}


variable "configmanagement_templates" {
  description = "Sets of config management configurations that can be applied to member clusters, in config name => {options} format."
  type = map(object({
    version = optional(string)
    config_sync = object({
      git = optional(object({
        sync_repo                 = string
        policy_dir                = string
        gcp_service_account_email = optional(string)
        https_proxy               = optional(string)
        secret_type               = optional(string, "none")
        sync_branch               = optional(string)
        sync_rev                  = optional(string)
        sync_wait_secs            = optional(number)
      }))
      prevent_drift = optional(bool)
      source_format = optional(string, "hierarchy")
    })
    hierarchy_controller = optional(object({
      enable_hierarchical_resource_quota = optional(bool)
      enable_pod_tree_labels             = optional(bool)
    }))
    policy_controller = optional(any) # DEPRECATED: Use policycontroller_templates instead
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.configmanagement_templates : v.policy_controller == null
    ])
    error_message = "The 'policy_controller' field in configmanagement_templates is deprecated. Please use the 'policycontroller_templates' variable instead to configure Policy Controller with its own API."
  }
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    locations   = optional(map(string), {})
    project_ids = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "features" {
  description = "Enable and configure fleet features."
  type = object({
    appdevexperience             = optional(bool, false)
    configmanagement             = optional(bool, false)
    identityservice              = optional(bool, false)
    multiclusteringress          = optional(string, null)
    multiclusterservicediscovery = optional(bool, false)
    policycontroller             = optional(bool, false)
    servicemesh                  = optional(bool, false)
  })
  default  = {}
  nullable = false
}

variable "fleet_default_member_config" {
  description = "Fleet default member config."
  type = object({
    mesh = optional(object({
      management = optional(string, "MANAGEMENT_AUTOMATIC")
    }))
    configmanagement = optional(object({
      version = optional(string)
      config_sync = optional(object({
        prevent_drift = optional(bool)
        source_format = optional(string, "hierarchy")
        enabled       = optional(bool)
        git = optional(object({
          gcp_service_account_email = optional(string)
          https_proxy               = optional(string)
          policy_dir                = optional(string)
          secret_type               = optional(string, "none")
          sync_branch               = optional(string)
          sync_repo                 = optional(string)
          sync_rev                  = optional(string)
          sync_wait_secs            = optional(number)
        }))
      }))
    }))
    policycontroller = optional(object({
      version = optional(string)
      policy_controller_hub_config = object({
        audit_interval_seconds     = optional(number)
        constraint_violation_limit = optional(number)
        exemptable_namespaces      = optional(list(string))
        install_spec               = optional(string)
        log_denies_enabled         = optional(bool)
        mutation_enabled           = optional(bool)
        referential_rules_enabled  = optional(bool)
        deployment_configs = optional(map(object({
          container_resources = optional(object({
            limits = optional(object({
              cpu    = optional(string)
              memory = optional(string)
            }))
            requests = optional(object({
              cpu    = optional(string)
              memory = optional(string)
            }))
          }))
          pod_affinity = optional(string)
          pod_toleration = optional(list(object({
            key      = optional(string)
            operator = optional(string)
            value    = optional(string)
            effect   = optional(string)
          })), [])
          replica_count = optional(number)
        })))
        monitoring = optional(object({
          backends = optional(list(string))
        }))
        policy_content = optional(object({
          bundles = optional(map(object({
            exempted_namespaces = optional(list(string))
          })))
          template_library = optional(object({
            installation = optional(string)
          }))
        }))
      })
    }))
  })
  default  = null
  nullable = true
}

variable "location" {
  description = "GKE hub location, will also be used for the membership location."
  type        = string
  default     = null
  nullable    = true
}

variable "policycontroller_templates" {
  description = "Sets of Policy Controller configurations that can be applied to member clusters, in config name => {options} format."
  type = map(object({
    version = optional(string)
    policy_controller_hub_config = object({
      audit_interval_seconds     = optional(number)
      constraint_violation_limit = optional(number)
      exemptable_namespaces      = optional(list(string))
      install_spec               = optional(string)
      log_denies_enabled         = optional(bool)
      mutation_enabled           = optional(bool)
      referential_rules_enabled  = optional(bool)
      deployment_configs = optional(map(object({
        container_resources = optional(object({
          limits = optional(object({
            cpu    = optional(string)
            memory = optional(string)
          }))
          requests = optional(object({
            cpu    = optional(string)
            memory = optional(string)
          }))
        }))
        pod_affinity = optional(string)
        pod_tolerations = optional(list(object({
          key      = optional(string)
          operator = optional(string)
          value    = optional(string)
          effect   = optional(string)
        })), [])
        replica_count = optional(number)
      })))
      monitoring = optional(object({
        backends = optional(list(string))
      }))
      policy_content = optional(object({
        bundles = optional(map(object({
          exempted_namespaces = optional(list(string))
        })))
        template_library = optional(object({
          installation = optional(string)
        }))
      }))
    })
  }))
  default  = {}
  nullable = false
}

variable "project_id" {
  description = "GKE hub project ID."
  type        = string
}

variable "servicemesh_templates" {
  description = "Sets of Service Mesh configurations that can be applied to member clusters, in config name => {options} format."
  type = map(object({
    management = optional(string, "MANAGEMENT_AUTOMATIC")
  }))
  default  = {}
  nullable = false
}
