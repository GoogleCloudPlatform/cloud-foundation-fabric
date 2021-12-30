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

# this code implements "additive" service perimeters, if "authoritative"
# service perimeters are needed, switch to the
# google_access_context_manager_service_perimeters resource

resource "google_access_context_manager_service_perimeter" "default" {
  for_each       = var.service_perimeters
  parent         = "accessPolicies/${local.access_policy}"
  name           = "accessPolicies/${local.access_policy}/servicePerimeters/${each.key}"
  title          = each.key
  perimeter_type = each.value.type
  spec {
    access_levels       = each.value.access_levels
    resources           = each.value.resources
    restricted_services = each.value.restricted_services
    # begin egress_policies
    dynamic "egress_policies" {
      for_each = toset(
        each.value.egress_policies == null ? [] : each.value.egress_policies
      )
      iterator = policy
      content {
        # begin egress_from
        dynamic "egress_from" {
          for_each = policy.key.egress_from == null ? {} : { 1 = 1 }
          content {
            identity_type = policy.key.egress_from.identity_type
            identities    = policy.key.egress_from.identities
          }
        }
        # end egress_from
        # begin egress_to
        dynamic "egress_to" {
          for_each = policy.key.egress_to == null ? {} : { 1 = 1 }
          content {
            resources = policy.key.egress_to.resources
            dynamic "operations" {
              for_each = toset(
                policy.key.egress_to.operations == null
                ? []
                : policy.key.egress_to.operations
              )
              iterator = operation
              content {
                service_name = operation.service_name
                dynamic "method_selectors" {
                  for_each = toset(
                    operation.key.method_selectors == null
                    ? []
                    : operation.key.method_selectors
                  )
                  content {
                    method = method_selectors.key
                  }
                }
              }
            }
          }
        }
        # end egress_to
      }
    }
    # end egress_policies
    # begin ingress_policies
    dynamic "ingress_policies" {
      for_each = toset(
        each.value.ingress_policies == null ? [] : each.value.ingress_policies
      )
      iterator = policy
      content {
        # begin ingress_from
        dynamic "ingress_from" {
          for_each = policy.key.ingress_from == null ? {} : { 1 = 1 }
          content {
            identity_type = policy.key.ingress_from.identity_type
            identities    = policy.key.ingress_from.identities
            # begin sources
            dynamic "sources" {
              for_each = toset(
                policy.key.ingress_from.source_access_levels == null
                ? []
                : policy.key.ingress_from.source_access_levels
              )
              content {
                access_level = sources.key
              }
            }
            dynamic "sources" {
              for_each = toset(
                policy.key.ingress_from.source_resources == null
                ? []
                : policy.key.ingress_from.source_resources
              )
              content {
                resource = sources.key
              }
            }
            # end sources
          }
        }
        # end ingress_from
        # begin ingress_to
        dynamic "ingress_to" {
          for_each = policy.key.ingress_to == null ? {} : { 1 = 1 }
          content {
            resources = policy.key.ingress_to.resources
            dynamic "operations" {
              for_each = toset(
                policy.key.ingress_to.operations == null
                ? []
                : policy.key.ingress_to.operations
              )
              iterator = operation
              content {
                service_name = operation.service_name
                dynamic "method_selectors" {
                  for_each = toset(
                    operation.key.method_selectors == null
                    ? []
                    : operation.key.method_selectors
                  )
                  content {
                    method = method_selectors.key
                  }
                }
              }
            }
          }
        }
        # end ingress_to
      }
    }
    # end ingress_policies
    # begin vpc_accessible_services
    dynamic "vpc_accessible_services" {
      for_each = toset(
        each.value.vpc_accessible_services == null
        ? []
        : each.value.vpc_accessible_services
      )
      content {
        allowed_services   = vpc_accessible_services.allowed_services
        enable_restriction = vpc_accessible_services.enable_restriction
      }
    }
    # end vpc_accessible_services
  }
  status {
    access_levels       = each.value.access_levels
    resources           = each.value.resources
    restricted_services = each.value.restricted_services
    # begin egress_policies
    dynamic "egress_policies" {
      for_each = toset(
        each.value.egress_policies == null ? [] : each.value.egress_policies
      )
      iterator = policy
      content {
        # begin egress_from
        dynamic "egress_from" {
          for_each = policy.key.egress_from == null ? {} : { 1 = 1 }
          content {
            identity_type = policy.key.egress_from.identity_type
            identities    = policy.key.egress_from.identities
          }
        }
        # end egress_from
        # begin egress_to
        dynamic "egress_to" {
          for_each = policy.key.egress_to == null ? {} : { 1 = 1 }
          content {
            resources = policy.key.egress_to.resources
            dynamic "operations" {
              for_each = toset(
                policy.key.egress_to.operations == null
                ? []
                : policy.key.egress_to.operations
              )
              iterator = operation
              content {
                service_name = operation.service_name
                dynamic "method_selectors" {
                  for_each = toset(
                    operation.key.method_selectors == null
                    ? []
                    : operation.key.method_selectors
                  )
                  content {
                    method = method_selectors.key
                  }
                }
              }
            }
          }
        }
        # end egress_to
      }
    }
    # end egress_policies
    # begin ingress_policies
    dynamic "ingress_policies" {
      for_each = toset(
        each.value.ingress_policies == null ? [] : each.value.ingress_policies
      )
      iterator = policy
      content {
        # begin ingress_from
        dynamic "ingress_from" {
          for_each = policy.key.ingress_from == null ? {} : { 1 = 1 }
          content {
            identity_type = policy.key.ingress_from.identity_type
            identities    = policy.key.ingress_from.identities
            # begin sources
            dynamic "sources" {
              for_each = toset(
                policy.key.ingress_from.source_access_levels == null
                ? []
                : policy.key.ingress_from.source_access_levels
              )
              content {
                access_level = sources.key
              }
            }
            dynamic "sources" {
              for_each = toset(
                policy.key.ingress_from.source_resources == null
                ? []
                : policy.key.ingress_from.source_resources
              )
              content {
                resource = sources.key
              }
            }
            # end sources
          }
        }
        # end ingress_from
        # begin ingress_to
        dynamic "ingress_to" {
          for_each = policy.key.ingress_to == null ? {} : { 1 = 1 }
          content {
            resources = policy.key.ingress_to.resources
            dynamic "operations" {
              for_each = toset(
                policy.key.ingress_to.operations == null
                ? []
                : policy.key.ingress_to.operations
              )
              iterator = operation
              content {
                service_name = operation.service_name
                dynamic "method_selectors" {
                  for_each = toset(
                    operation.key.method_selectors == null
                    ? []
                    : operation.key.method_selectors
                  )
                  content {
                    method = method_selectors.key
                  }
                }
              }
            }
          }
        }
        # end ingress_to
      }
    }
    # end ingress_policies
    # begin vpc_accessible_services
    dynamic "vpc_accessible_services" {
      for_each = toset(
        each.value.vpc_accessible_services == null
        ? []
        : each.value.vpc_accessible_services
      )
      content {
        allowed_services   = vpc_accessible_services.allowed_services
        enable_restriction = vpc_accessible_services.enable_restriction
      }
    }
    # end vpc_accessible_services
  }
  use_explicit_dry_run_spec = true
  depends_on = [
    google_access_context_manager_access_policy.default,
    google_access_context_manager_access_level.basic
  ]
}
