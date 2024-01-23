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

# tfdoc:file:description Cloud Dataproc resource definition.

locals {
  prefix = var.prefix == null ? "" : "${var.prefix}-"
}

resource "google_dataproc_cluster" "cluster" {
  name                          = "${local.prefix}${var.name}"
  project                       = var.project_id
  region                        = var.region
  graceful_decommission_timeout = var.dataproc_config.graceful_decommission_timeout
  labels                        = var.labels
  dynamic "cluster_config" {
    for_each = var.dataproc_config.cluster_config == null ? [] : [""]
    content {
      staging_bucket = var.dataproc_config.cluster_config.staging_bucket
      temp_bucket    = var.dataproc_config.cluster_config.temp_bucket
      dynamic "gce_cluster_config" {
        for_each = var.dataproc_config.cluster_config.gce_cluster_config == null ? [] : [""]
        content {
          zone                   = var.dataproc_config.cluster_config.gce_cluster_config.zone
          network                = var.dataproc_config.cluster_config.gce_cluster_config.network
          subnetwork             = var.dataproc_config.cluster_config.gce_cluster_config.subnetwork
          service_account        = var.dataproc_config.cluster_config.gce_cluster_config.service_account
          service_account_scopes = var.dataproc_config.cluster_config.gce_cluster_config.service_account_scopes
          tags                   = var.dataproc_config.cluster_config.gce_cluster_config.tags
          internal_ip_only       = var.dataproc_config.cluster_config.gce_cluster_config.internal_ip_only
          metadata               = var.dataproc_config.cluster_config.gce_cluster_config.metadata
          dynamic "reservation_affinity" {
            for_each = var.dataproc_config.cluster_config.gce_cluster_config.reservation_affinity == null ? [] : [""]
            content {
              consume_reservation_type = var.dataproc_config.cluster_config.gce_cluster_config.reservation_affinity.consume_reservation_type
              key                      = var.dataproc_config.cluster_config.gce_cluster_config.reservation_affinity.key
              values                   = var.dataproc_config.cluster_config.gce_cluster_config.reservation_affinity.value
            }
          }
          dynamic "node_group_affinity" {
            for_each = var.dataproc_config.cluster_config.gce_cluster_config.node_group_affinity == null ? [] : [""]
            content {
              node_group_uri = var.dataproc_config.cluster_config.gce_cluster_config.node_group_uri
            }
          }
          dynamic "shielded_instance_config" {
            for_each = var.dataproc_config.cluster_config.gce_cluster_config.shielded_instance_config == null ? [] : [""]
            content {
              enable_secure_boot          = var.dataproc_config.cluster_config.gce_cluster_config.shielded_instance_config.enable_secure_boot
              enable_vtpm                 = var.dataproc_config.cluster_config.gce_cluster_config.shielded_instance_config.enable_vtpm
              enable_integrity_monitoring = var.dataproc_config.cluster_config.gce_cluster_config.shielded_instance_config.enable_integrity_monitoring
            }
          }
        }
      }
      dynamic "master_config" {
        for_each = var.dataproc_config.cluster_config.master_config == null ? [] : [""]
        content {
          num_instances    = var.dataproc_config.cluster_config.master_config.num_instances
          machine_type     = var.dataproc_config.cluster_config.master_config.machine_type
          min_cpu_platform = var.dataproc_config.cluster_config.master_config.min_cpu_platform
          image_uri        = var.dataproc_config.cluster_config.master_config.image_uri
          dynamic "disk_config" {
            for_each = var.dataproc_config.cluster_config.master_config.disk_config == null ? [] : [""]
            content {
              boot_disk_type    = var.dataproc_config.cluster_config.master_config.disk_config.boot_disk_type
              boot_disk_size_gb = var.dataproc_config.cluster_config.master_config.disk_config.boot_disk_size_gb
              num_local_ssds    = var.dataproc_config.cluster_config.master_config.disk_config.num_local_ssds
            }
          }
          dynamic "accelerators" {
            for_each = var.dataproc_config.cluster_config.master_config.accelerators == null ? [] : [""]
            content {
              accelerator_type  = var.dataproc_config.cluster_config.master_config.accelerators.accelerator_type
              accelerator_count = var.dataproc_config.cluster_config.master_config.accelerators.accelerator_count
            }
          }
        }
      }
      dynamic "worker_config" {
        for_each = var.dataproc_config.cluster_config.worker_config == null ? [] : [""]
        content {
          num_instances    = var.dataproc_config.cluster_config.worker_config.num_instances
          machine_type     = var.dataproc_config.cluster_config.worker_config.machine_type
          min_cpu_platform = var.dataproc_config.cluster_config.worker_config.min_cpu_platform
          dynamic "disk_config" {
            for_each = var.dataproc_config.cluster_config.worker_config.disk_config == null ? [] : [""]
            content {
              boot_disk_type    = var.dataproc_config.cluster_config.worker_config.disk_config.boot_disk_type
              boot_disk_size_gb = var.dataproc_config.cluster_config.worker_config.disk_config.boot_disk_size_gb
              num_local_ssds    = var.dataproc_config.cluster_config.worker_config.disk_config.num_local_ssds
            }
          }
          image_uri = var.dataproc_config.cluster_config.worker_config.image_uri
          dynamic "accelerators" {
            for_each = var.dataproc_config.cluster_config.worker_config.accelerators == null ? [] : [""]
            content {
              accelerator_type  = var.dataproc_config.cluster_config.worker_config.accelerators.accelerator_type
              accelerator_count = var.dataproc_config.cluster_config.worker_config.accelerators.accelerator_count
            }
          }
        }
      }
      dynamic "preemptible_worker_config" {
        for_each = var.dataproc_config.cluster_config.preemptible_worker_config == null ? [] : [""]
        content {
          num_instances  = var.dataproc_config.cluster_config.preemptible_worker_config.num_instances
          preemptibility = var.dataproc_config.cluster_config.preemptible_worker_config.preemptibility
          dynamic "disk_config" {
            for_each = var.dataproc_config.cluster_config.preemptible_worker_config.disk_config == null ? [] : [""]
            content {
              boot_disk_type    = var.dataproc_config.cluster_config.disk_config.boot_disk_type
              boot_disk_size_gb = var.dataproc_config.cluster_config.disk_config.boot_disk_size_gb
              num_local_ssds    = var.dataproc_config.cluster_config.disk_config.num_local_ssds
            }
          }
        }
      }
      dynamic "software_config" {
        for_each = var.dataproc_config.cluster_config.software_config == null ? [] : [""]
        content {
          image_version       = var.dataproc_config.cluster_config.software_config.image_version
          override_properties = var.dataproc_config.cluster_config.software_config.override_properties
          optional_components = var.dataproc_config.cluster_config.software_config.optional_components
        }
      }
      dynamic "security_config" {
        for_each = var.dataproc_config.cluster_config.security_config == null ? [] : [""]
        content {
          dynamic "kerberos_config" {
            for_each = try(var.dataproc_config.cluster_config.security_config.kerberos_config == null ? [] : [""], [])
            content {
              cross_realm_trust_admin_server        = var.dataproc_config.cluster_config.kerberos_config.cross_realm_trust_admin_server
              cross_realm_trust_kdc                 = var.dataproc_config.cluster_config.kerberos_config.cross_realm_trust_kdc
              cross_realm_trust_realm               = var.dataproc_config.cluster_config.kerberos_config.cross_realm_trust_realm
              cross_realm_trust_shared_password_uri = var.dataproc_config.cluster_config.kerberos_config.cross_realm_trust_shared_password_uri
              enable_kerberos                       = var.dataproc_config.cluster_config.kerberos_config.enable_kerberos
              kdc_db_key_uri                        = var.dataproc_config.cluster_config.kerberos_config.kdc_db_key_uri
              key_password_uri                      = var.dataproc_config.cluster_config.kerberos_config.key_password_uri
              keystore_uri                          = var.dataproc_config.cluster_config.kerberos_config.keystore_uri
              keystore_password_uri                 = var.dataproc_config.cluster_config.kerberos_config.keystore_password_uri
              kms_key_uri                           = var.dataproc_config.cluster_config.kerberos_config.kms_key_uri
              realm                                 = var.dataproc_config.cluster_config.kerberos_config.realm
              root_principal_password_uri           = var.dataproc_config.cluster_config.kerberos_config.root_principal_password_uri
              tgt_lifetime_hours                    = var.dataproc_config.cluster_config.kerberos_config.tgt_lifetime_hours
              truststore_password_uri               = var.dataproc_config.cluster_config.kerberos_config.truststore_password_uri
              truststore_uri                        = var.dataproc_config.cluster_config.kerberos_config.truststore_uri
            }
          }
        }
      }
      dynamic "autoscaling_config" {
        for_each = var.dataproc_config.cluster_config.autoscaling_config == null ? [] : [""]
        content {
          policy_uri = var.dataproc_config.cluster_config.autoscaling_config.policy_uri
        }
      }
      dynamic "initialization_action" {
        for_each = var.dataproc_config.cluster_config.initialization_action == null ? [] : [""]
        content {
          script      = var.dataproc_config.cluster_config.initialization_action.script
          timeout_sec = var.dataproc_config.cluster_config.initialization_action.timeout_sec
        }
      }
      dynamic "encryption_config" {
        for_each = try(var.dataproc_config.cluster_config.encryption_config.kms_key_name == null ? [] : [""], [])
        content {
          kms_key_name = var.dataproc_config.cluster_config.encryption_config.kms_key_name
        }
      }
      dynamic "dataproc_metric_config" {
        for_each = var.dataproc_config.cluster_config.dataproc_metric_config == null ? [] : [""]
        content {
          dynamic "metrics" {
            for_each = coalesce(var.dataproc_config.cluster_config.dataproc_metric_config.metrics, [])
            content {
              metric_source    = metrics.value.metric_source
              metric_overrides = metrics.value.metric_overrides
            }
          }
        }
      }
      dynamic "lifecycle_config" {
        for_each = var.dataproc_config.cluster_config.lifecycle_config == null ? [] : [""]
        content {
          idle_delete_ttl  = var.dataproc_config.cluster_config.lifecycle_config.idle_delete_ttl
          auto_delete_time = var.dataproc_config.cluster_config.lifecycle_config.auto_delete_time
        }
      }
      dynamic "endpoint_config" {
        for_each = var.dataproc_config.cluster_config.endpoint_config == null ? [] : [""]
        content {
          enable_http_port_access = var.dataproc_config.cluster_config.endpoint_config.enable_http_port_access
        }
      }
      dynamic "metastore_config" {
        for_each = var.dataproc_config.cluster_config.metastore_config == null ? [] : [""]
        content {
          dataproc_metastore_service = var.dataproc_config.cluster_config.metastore_config.dataproc_metastore_service
        }
      }

    }
  }

  dynamic "virtual_cluster_config" {
    for_each = var.dataproc_config.virtual_cluster_config == null ? [] : [""]
    content {
      dynamic "auxiliary_services_config" {
        for_each = var.dataproc_config.virtual_cluster_config.auxiliary_services_config == null ? [] : [""]
        content {
          dynamic "metastore_config" {
            for_each = var.dataproc_config.virtual_cluster_config.auxiliary_services_config.metastore_config == null ? [] : [""]
            content {
              dataproc_metastore_service = var.dataproc_config.virtual_cluster_config.auxiliary_services_config.metastore_config.dataproc_metastore_service
            }
          }
          dynamic "spark_history_server_config" {
            for_each = var.dataproc_config.virtual_cluster_config.auxiliary_services_config.spark_history_server_config == null ? [] : [""]
            content {
              dataproc_cluster = var.dataproc_config.virtual_cluster_config.auxiliary_services_config.spark_history_server_config.dataproc_cluster
            }
          }
        }
      }
      dynamic "kubernetes_cluster_config" {
        for_each = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config == null ? [] : [""]
        content {
          kubernetes_namespace = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.kubernetes_namespace
          dynamic "kubernetes_software_config" {
            for_each = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.kubernetes_software_config == null ? [] : [""]
            content {
              component_version = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.kubernetes_software_config.component_version
              properties        = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.kubernetes_software_config.properties
            }
          }

          dynamic "gke_cluster_config" {
            for_each = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config == null ? [] : [""]
            content {
              gke_cluster_target = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.gke_cluster_target
              dynamic "node_pool_target" {
                for_each = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_target == null ? [] : [""]
                content {
                  node_pool = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_target.node_pool
                  roles     = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_target.roles
                  dynamic "node_pool_config" {
                    for_each = try(var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_config == null ? [] : [""], [])
                    content {
                      dynamic "autoscaling" {
                        for_each = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_config.autoscaling == null ? [] : [""]
                        content {
                          min_node_count = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_config.autoscaling.min_node_count
                          max_node_count = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_config.autoscaling.max_node_count
                        }
                      }
                      dynamic "config" {
                        for_each = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_config.config == null ? [] : [""]
                        content {
                          machine_type     = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_config.config.machine_type
                          local_ssd_count  = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_config.config.local_ssd_count
                          preemptible      = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_config.config.preemptible
                          min_cpu_platform = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_config.config.min_cpu_platform
                          spot             = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_config.config.spot
                        }
                      }
                      locations = var.dataproc_config.virtual_cluster_config.kubernetes_cluster_config.gke_cluster_config.node_pool_config.locations
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      # Some scopes are assigned in addition to the one configured
      # https://cloud.google.com/dataproc/docs/concepts/configuring-clusters/service-accounts#dataproc_vm_access_scopes
      cluster_config[0].gce_cluster_config[0].service_account_scopes,
    ]
  }
}
