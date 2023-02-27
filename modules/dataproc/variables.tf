/**
 * Copyright 2023 Google LLC
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

variable "service_account" {
  description = "Service account to set on the Dataproc cluster."
  type        = string
  default     = null
}

variable "group_iam" {
  description = "Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_additive" {
  description = "IAM additive bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "labels" {
  description = "The resource labels for instance to use to annotate any related underlying resources, such as Compute Engine VMs."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Cluster name."
  type        = string
}

variable "prefix" {
  description = "Optional prefix used to generate project id and name."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "region" {
  description = "Dataproc region."
  type        = string
}

variable "dataproc_config" {
  description = "Dataproc cluster config."
  type = object({
    graceful_decommission_timeout = optional(string, null)
    cluster_config = optional(object({
      staging_bucket = optional(string, null)
      temp_bucket    = optional(string, null)
      gce_cluster_config = optional(object({
        zone                   = optional(string, null)
        network                = optional(string, null)
        subnetwork             = optional(string, null)
        service_account        = optional(string, null)
        service_account_scopes = optional(list(string), null)
        tags                   = optional(list(string), [])
        internal_ip_only       = optional(bool, null)
        metadata               = optional(map(string), {})
        reservation_affinity = optional(object({
          consume_reservation_type = string
          key                      = string
          values                   = string
        }), null)
        node_group_affinity = optional(object({
          node_group_uri = string
        }), null)

        shielded_instance_config = optional(object({
          enable_secure_boot          = bool
          enable_vtpm                 = bool
          enable_integrity_monitoring = bool
        }), null)
      }), null)
      master_config = optional(object({
        num_instances    = number
        machine_type     = string
        min_cpu_platform = string
        disk_config = optional(object({
          boot_disk_type    = string
          boot_disk_size_gb = number
          num_local_ssds    = number
        }), null)
        accelerators = optional(object({
          accelerator_type  = string
          accelerator_count = number
        }), null)
      }), null)
      worker_config = optional(object({
        num_instances    = number
        machine_type     = string
        min_cpu_platform = string
        disk_config = optional(object({
          boot_disk_type    = string
          boot_disk_size_gb = number
          num_local_ssds    = number
        }), null)
        image_uri = string
        accelerators = optional(object({
          accelerator_type  = string
          accelerator_count = number
        }), null)
      }), null)
      preemptible_worker_config = optional(object({
        num_instances  = number
        preemptibility = string
        disk_config = optional(object({
          boot_disk_type    = string
          boot_disk_size_gb = number
          num_local_ssds    = number
        }), null)
      }), null)
      software_config = optional(object({
        image_version       = string
        override_properties = list(map(string))
        optional_components = list(string)
      }), null)
      security_config = optional(object({
        kerberos_config = object({
          cross_realm_trust_admin_server        = optional(string, null)
          cross_realm_trust_kdc                 = optional(string, null)
          cross_realm_trust_realm               = optional(string, null)
          cross_realm_trust_shared_password_uri = optional(string, null)
          enable_kerberos                       = optional(string, null)
          kdc_db_key_uri                        = optional(string, null)
          key_password_uri                      = optional(string, null)
          keystore_uri                          = optional(string, null)
          keystore_password_uri                 = optional(string, null)
          kms_key_uri                           = string
          realm                                 = optional(string, null)
          root_principal_password_uri           = string
          tgt_lifetime_hours                    = optional(string, null)
          truststore_password_uri               = optional(string, null)
          truststore_uri                        = optional(string, null)
        })
      }), null)
      autoscaling_config = optional(object({
        policy_uri = string
      }), null)
      initialization_action = optional(object({
        script      = string
        timeout_sec = optional(string, null)
      }), null)
      encryption_config = optional(object({
        kms_key_name = string
      }), null)
      lifecycle_config = optional(object({
        idle_delete_ttl  = optional(string, null)
        auto_delete_time = optional(string, null)
      }), null)
      endpoint_config = optional(object({
        enable_http_port_access = string
      }), null)
      dataproc_metric_config = optional(object({
        metrics = list(object({
          metric_source    = string
          metric_overrides = optional(string, null)
        }))
      }), null)
      metastore_config = optional(object({
        dataproc_metastore_service = string
      }), null)
    }), null)

    virtual_cluster_config = optional(object({
      staging_bucket = optional(string, null)
      auxiliary_services_config = optional(object({
        metastore_config = optional(object({
          dataproc_metastore_service = string
        }), null)
        spark_history_server_config = optional(object({
          dataproc_cluster = string
        }), null)
      }), null)
      kubernetes_cluster_config = object({
        kubernetes_namespace = optional(string, null)
        kubernetes_software_config = object({
          component_version = list(map(string))
          properties        = optional(list(map(string)), null)
        })

        gke_cluster_config = object({
          gke_cluster_target = optional(string, null)
          node_pool_target = optional(object({
            node_pool = string
            roles     = list(string)
            node_pool_config = optional(object({
              autoscaling = optional(object({
                min_node_count = optional(number, null)
                max_node_count = optional(number, null)
              }), null)

              config = object({
                machine_type     = optional(string, null)
                preemptible      = optional(bool, null)
                local_ssd_count  = optional(number, null)
                min_cpu_platform = optional(string, null)
                spot             = optional(bool, null)
              })

              locations = optional(list(string), null)
            }), null)
          }), null)
        })
      })
    }), null)
  })
  default = {}
}
