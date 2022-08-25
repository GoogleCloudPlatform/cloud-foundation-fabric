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

# we deal with one env here
# 1 project, m clusters
# cloud dns for gke?

variable "automation" {
  # tfdoc:variable:source 00-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type = object({
    outputs_bucket = string
  })
}

variable "authenticator_security_group" {
  description = "Optional group used for Groups for GKE."
  type        = string
  default     = null
}

variable "billing_account" {
  # tfdoc:variable:source 00-bootstrap
  description = "Billing account id and organization id ('nnnnnnnn' or null)."
  type = object({
    id              = string
    organization_id = number
  })
}

variable "cluster_defaults" {
  description = "Default values for optional cluster configurations."
  type = object({
    cloudrun_config                 = bool
    database_encryption_key         = string
    master_authorized_ranges        = map(string)
    max_pods_per_node               = number
    pod_security_policy             = bool
    release_channel                 = string
    vertical_pod_autoscaling        = bool
    gcp_filestore_csi_driver_config = bool
  })
  default = {
    cloudrun_config         = false
    database_encryption_key = null
    # binary_authorization    = false
    master_authorized_ranges = {
      rfc1918_1 = "10.0.0.0/8"
      rfc1918_2 = "172.16.0.0/12"
      rfc1918_3 = "192.168.0.0/16"
    }
    max_pods_per_node               = 110
    pod_security_policy             = false
    release_channel                 = "STABLE"
    vertical_pod_autoscaling        = false
    gcp_filestore_csi_driver_config = false
  }
}

variable "clusters" {
  description = ""
  type = map(object({
    cluster_autoscaling = object({
      cpu_min    = number
      cpu_max    = number
      memory_min = number
      memory_max = number
    })
    description = string
    dns_domain  = string
    labels      = map(string)
    location    = string
    net = object({
      master_range = string
      pods         = string
      services     = string
      subnet       = string
    })
    overrides = object({
      cloudrun_config         = bool
      database_encryption_key = string
      # binary_authorization            = bool
      master_authorized_ranges        = map(string)
      max_pods_per_node               = number
      pod_security_policy             = bool
      release_channel                 = string
      vertical_pod_autoscaling        = bool
      gcp_filestore_csi_driver_config = bool
    })
  }))
}

variable "dns_domain" {
  description = "Domain name used for clusters, prefixed by each cluster name. Leave null to disable Cloud DNS for GKE."
  type        = string
  default     = null
}

variable "fleet_configmanagement_clusters" {
  description = "Config management features enabled on specific sets of member clusters, in config name => [cluster name] format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}


variable "fleet_configmanagement_templates" {
  description = "Sets of config management configurations that can be applied to member clusters, in config name => {options} format."
  type = map(object({
    binauthz = bool
    config_sync = object({
      git = object({
        gcp_service_account_email = string
        https_proxy               = string
        policy_dir                = string
        secret_type               = string
        sync_branch               = string
        sync_repo                 = string
        sync_rev                  = string
        sync_wait_secs            = number
      })
      prevent_drift = string
      source_format = string
    })
    hierarchy_controller = object({
      enable_hierarchical_resource_quota = bool
      enable_pod_tree_labels             = bool
    })
    policy_controller = object({
      audit_interval_seconds     = number
      exemptable_namespaces      = list(string)
      log_denies_enabled         = bool
      referential_rules_enabled  = bool
      template_library_installed = bool
    })
    version = string
  }))
  default  = {}
  nullable = false
}

variable "fleet_features" {
  description = "Enable and configue fleet features. Set to null to disable GKE Hub if fleet workload identity is not used."
  type = object({
    appdevexperience             = bool
    configmanagement             = bool
    identityservice              = bool
    multiclusteringress          = string
    multiclusterservicediscovery = bool
    servicemesh                  = bool
  })
  default = null
}

variable "fleet_workload_identity" {
  description = "Use Fleet Workload Identity for clusters. Enables GKE Hub if set to true."
  type        = bool
  default     = false
  nullable    = false
}

variable "folder_ids" {
  # tfdoc:variable:source 01-resman
  description = "Folders to be used for the networking resources in folders/nnnnnnnnnnn format. If null, folder will be created."
  type = object({
    gke-dev = string
  })
}

variable "group_iam" {
  description = "Project-level authoritative IAM bindings for groups in {GROUP_EMAIL => [ROLES]} format. Use group emails as keys, list of roles as values."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam" {
  description = "Project-level authoritative IAM bindings for users and service accounts in  {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "host_project_ids" {
  # tfdoc:variable:source 02-networking
  description = "Host project for the shared VPC."
  type = object({
    dev-spoke-0 = string
  })
}

variable "labels" {
  description = "Project-level labels."
  type        = map(string)
  default     = {}
}

variable "nodepool_defaults" {
  description = ""
  type = object({
    image_type        = string
    max_pods_per_node = number
    node_locations    = list(string)
    node_tags         = list(string)
    node_taints       = list(string)
  })
  default = {
    image_type        = "COS_CONTAINERD"
    max_pods_per_node = 110
    node_locations    = null
    node_tags         = null
    node_taints       = []
  }
}

variable "nodepools" {
  description = ""
  type = map(map(object({
    node_count         = number
    node_type          = string
    initial_node_count = number
    overrides = object({
      image_type        = string
      max_pods_per_node = number
      node_locations    = list(string)
      node_tags         = list(string)
      node_taints       = list(string)
    })
    spot = bool
  })))
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
}

variable "project_services" {
  description = "Additional project services to enable."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "vpc_self_links" {
  # tfdoc:variable:source 02-networking
  description = "Self link for the shared VPC."
  type = object({
    dev-spoke-0 = string
  })
}
