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

locals {
  # Filter and prepare config management configurations
  cluster_cm_config = {
    for key, cluster in var.clusters :
    key => lookup(var.configmanagement_templates, cluster.configmanagement, null)
    if cluster.configmanagement != null &&
    var.features.configmanagement == true &&
    lookup(var.configmanagement_templates, cluster.configmanagement, null) != null
  }

  # Filter and prepare policy controller configurations
  cluster_pc_config = {
    for key, cluster in var.clusters :
    key => lookup(var.policycontroller_templates, cluster.policycontroller, null)
    if cluster.policycontroller != null &&
    var.features.policycontroller == true &&
    lookup(var.policycontroller_templates, cluster.policycontroller, null) != null
  }

  # Filter and prepare service mesh configurations
  cluster_mesh_config = {
    for key, cluster in var.clusters :
    key => lookup(var.servicemesh_templates, cluster.servicemesh, null)
    if cluster.servicemesh != null &&
    var.features.servicemesh == true &&
    lookup(var.servicemesh_templates, cluster.servicemesh, null) != null
  }

  hub_features = {
    for k, v in var.features :
    k => v
    if v != null && v != false && v != ""
  }
}

resource "google_gke_hub_membership" "default" {
  provider      = google-beta
  for_each      = var.clusters
  project       = var.project_id
  location      = var.location
  membership_id = each.key
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${each.value.id}"
    }
  }
  dynamic "authority" {
    for_each = each.value.workload_identity ? [1] : []
    content {
      issuer = "https://container.googleapis.com/v1/${each.value.id}"
    }
  }
}

resource "google_gke_hub_feature" "default" {
  provider = google-beta
  for_each = local.hub_features
  project  = var.project_id
  name     = each.key
  location = "global"
  dynamic "spec" {
    for_each = each.key == "multiclusteringress" && each.value != null ? [1] : []
    content {
      multiclusteringress {
        config_membership = google_gke_hub_membership.default[each.value].id
      }
    }
  }
  dynamic "fleet_default_member_config" {
    for_each = var.fleet_default_member_config[*]
    content {
      dynamic "mesh" {
        for_each = var.fleet_default_member_config.mesh[*]
        content {
          management = mesh.value.management
        }
      }

      dynamic "configmanagement" {
        for_each = var.fleet_default_member_config.configmanagement[*]
        content {
          version = configmanagement.value.version

          dynamic "config_sync" {
            for_each = configmanagement.value.config_sync[*]
            content {
              prevent_drift = config_sync.value.prevent_drift
              source_format = config_sync.value.source_format
              enabled       = config_sync.value.enabled

              dynamic "git" {
                for_each = config_sync.value.git[*]
                content {
                  gcp_service_account_email = git.value.gcp_service_account_email
                  https_proxy               = git.value.https_proxy
                  policy_dir                = git.value.policy_dir
                  secret_type               = git.value.secret_type
                  sync_branch               = git.value.sync_branch
                  sync_repo                 = git.value.sync_repo
                  sync_rev                  = git.value.sync_rev
                  sync_wait_secs            = git.value.sync_wait_secs
                }
              }
            }
          }
        }
      }

      dynamic "policycontroller" {
        for_each = var.fleet_default_member_config.policycontroller[*]
        content {
          version = policycontroller.value.version

          policy_controller_hub_config {
            audit_interval_seconds     = policycontroller.value.policy_controller_hub_config.audit_interval_seconds
            constraint_violation_limit = policycontroller.value.policy_controller_hub_config.constraint_violation_limit
            exemptable_namespaces      = policycontroller.value.policy_controller_hub_config.exemptable_namespaces
            install_spec               = policycontroller.value.policy_controller_hub_config.install_spec
            log_denies_enabled         = policycontroller.value.policy_controller_hub_config.log_denies_enabled
            mutation_enabled           = policycontroller.value.policy_controller_hub_config.mutation_enabled
            referential_rules_enabled  = policycontroller.value.policy_controller_hub_config.referential_rules_enabled

            dynamic "deployment_configs" {
              for_each = policycontroller.value.policy_controller_hub_config.deployment_configs[*]
              content {
                component = deployment_configs.key

                dynamic "container_resources" {
                  for_each = deployment_configs.value.container_resources[*]
                  content {
                    dynamic "limits" {
                      for_each = deployment_configs.value.container_resources.limits[*]
                      content {
                        cpu    = limits.value.cpu
                        memory = limits.value.memory
                      }
                    }

                    dynamic "requests" {
                      for_each = deployment_configs.value.container_resources.requests[*]
                      content {
                        cpu    = requests.value.cpu
                        memory = requests.value.memory
                      }
                    }
                  }
                }

                pod_affinity = deployment_configs.value.pod_affinity

                dynamic "pod_toleration" {
                  for_each = deployment_configs.value.pod_toleration[*]
                  content {
                    key      = pod_toleration.value.key
                    operator = pod_toleration.value.operator
                    value    = pod_toleration.value.value
                    effect   = pod_toleration.value.effect
                  }
                }

                replica_count = deployment_configs.value.replica_count
              }
            }

            dynamic "monitoring" {
              for_each = policycontroller.value.policy_controller_hub_config.monitoring[*]
              content {
                backends = monitoring.value.backends
              }
            }

            dynamic "policy_content" {
              for_each = policycontroller.value.policy_controller_hub_config.policy_content[*]
              content {
                dynamic "bundles" {
                  for_each = policy_content.value.bundles == null ? {} : policy_content.value.bundles
                  content {
                    bundle              = bundles.key
                    exempted_namespaces = bundles.value.exempted_namespaces
                  }
                }

                dynamic "template_library" {
                  for_each = policycontroller.value.policy_controller_hub_config.policy_content.template_library[*]
                  content {
                    installation = template_library.value.installation
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

resource "google_gke_hub_feature_membership" "servicemesh" {
  provider            = google-beta
  for_each            = local.cluster_mesh_config
  project             = var.project_id
  location            = "global"
  feature             = google_gke_hub_feature.default["servicemesh"].name
  membership          = google_gke_hub_membership.default[each.key].membership_id
  membership_location = var.location

  mesh {
    management = each.value.management
  }
}

resource "google_gke_hub_feature_membership" "policycontroller" {
  provider            = google-beta
  for_each            = local.cluster_pc_config
  project             = var.project_id
  location            = "global"
  feature             = google_gke_hub_feature.default["policycontroller"].name
  membership          = google_gke_hub_membership.default[each.key].membership_id
  membership_location = var.location

  policycontroller {
    version = each.value.version

    policy_controller_hub_config {
      audit_interval_seconds     = each.value.policy_controller_hub_config.audit_interval_seconds
      constraint_violation_limit = each.value.policy_controller_hub_config.constraint_violation_limit

      dynamic "policy_content" {
        for_each = each.value.policy_controller_hub_config.policy_content[*]
        content {
          dynamic "bundles" {
            for_each = policy_content.value.bundles == null ? {} : policy_content.value.bundles
            content {
              bundle_name         = bundles.key
              exempted_namespaces = bundles.value.exempted_namespaces
            }
          }

          dynamic "template_library" {
            for_each = policy_content.value.template_library[*]
            content {
              installation = template_library.value.installation
            }
          }
        }
      }

      dynamic "deployment_configs" {
        for_each = each.value.policy_controller_hub_config.deployment_configs == null ? {} : each.value.policy_controller_hub_config.deployment_configs
        content {
          component_name = deployment_configs.key

          dynamic "container_resources" {
            for_each = deployment_configs.value.container_resources[*]
            content {
              dynamic "limits" {
                for_each = container_resources.value.limits[*]
                content {
                  cpu    = container_resources.value.limits.cpu
                  memory = container_resources.value.limits.memory
                }
              }

              dynamic "requests" {
                for_each = container_resources.value.requests[*]
                content {
                  cpu    = requests.value.cpu
                  memory = requests.value.memory
                }
              }
            }
          }

          pod_affinity = deployment_configs.value.pod_affinity

          dynamic "pod_tolerations" {
            for_each = deployment_configs.value.pod_tolerations[*]
            content {
              key      = pod_tolerations.value.key
              operator = pod_tolerations.value.operator
              value    = pod_tolerations.value.value
              effect   = pod_tolerations.value.effect
            }
          }

          replica_count = deployment_configs.value.replica_count
        }
      }

      exemptable_namespaces = each.value.policy_controller_hub_config.exemptable_namespaces
      install_spec          = each.value.policy_controller_hub_config.install_spec
      log_denies_enabled    = each.value.policy_controller_hub_config.log_denies_enabled

      dynamic "monitoring" {
        for_each = each.value.policy_controller_hub_config.monitoring[*]
        content {
          backends = monitoring.value.backends
        }
      }

      mutation_enabled          = each.value.policy_controller_hub_config.mutation_enabled
      referential_rules_enabled = each.value.policy_controller_hub_config.referential_rules_enabled
    }
  }
}

resource "google_gke_hub_feature_membership" "default" {
  provider            = google-beta
  for_each            = local.cluster_cm_config
  project             = var.project_id
  location            = "global"
  feature             = google_gke_hub_feature.default["configmanagement"].name
  membership          = google_gke_hub_membership.default[each.key].membership_id
  membership_location = var.location

  configmanagement {
    version = each.value.version

    dynamic "config_sync" {
      for_each = each.value.config_sync[*]
      content {
        prevent_drift = config_sync.value.prevent_drift
        source_format = config_sync.value.source_format
        enabled       = true
        dynamic "git" {
          for_each = config_sync.value.git[*]
          content {
            gcp_service_account_email = (
              git.value.gcp_service_account_email
            )
            https_proxy    = git.value.https_proxy
            policy_dir     = git.value.policy_dir
            secret_type    = git.value.secret_type
            sync_branch    = git.value.sync_branch
            sync_repo      = git.value.sync_repo
            sync_rev       = git.value.sync_rev
            sync_wait_secs = git.value.sync_wait_secs
          }
        }
      }
    }

    dynamic "hierarchy_controller" {
      for_each = each.value.hierarchy_controller[*]
      content {
        enable_hierarchical_resource_quota = (
          hierarchy_controller.value.enable_hierarchical_resource_quota
        )
        enable_pod_tree_labels = (
          hierarchy_controller.value.enable_pod_tree_labels
        )
        enabled = true
      }
    }
  }
}
