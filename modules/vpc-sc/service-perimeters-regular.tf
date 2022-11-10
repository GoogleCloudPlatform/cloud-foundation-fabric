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

# tfdoc:file:description Regular service perimeter resources.

# this code implements "additive" service perimeters, if "authoritative"
# service perimeters are needed, switch to the
# google_access_context_manager_service_perimeters resource

resource "google_access_context_manager_service_perimeter" "regular" {
  for_each                  = var.service_perimeters_regular
  parent                    = "accessPolicies/${local.access_policy}"
  name                      = "accessPolicies/${local.access_policy}/servicePerimeters/${each.key}"
  title                     = each.key
  perimeter_type            = "PERIMETER_TYPE_REGULAR"
  use_explicit_dry_run_spec = each.value.use_explicit_dry_run_spec
  dynamic "spec" {
    for_each = each.value.spec == null ? [] : [""]
    content {
      access_levels = (
        each.value.spec.access_levels == null ? null : [
          for k in each.value.spec.access_levels :
          try(google_access_context_manager_access_level.basic[k].id, k)
        ]
      )
      resources           = each.value.spec.resources
      restricted_services = each.value.spec.restricted_services

      dynamic "egress_policies" {
        for_each = each.value.spec.egress_policies == null ? {} : {
          for k in each.value.spec.egress_policies :
          k => lookup(var.egress_policies, k, null)
          if contains(keys(var.egress_policies), k)
        }
        iterator = policy
        content {
          dynamic "egress_from" {
            for_each = policy.value.from == null ? [] : [""]
            content {
              identity_type = policy.value.from.identity_type
              identities    = policy.value.from.identities
            }
          }
          dynamic "egress_to" {
            for_each = policy.value.to == null ? [] : [""]
            content {
              resources = policy.value.to.resources
              dynamic "operations" {
                for_each = toset(policy.value.to.operations)
                iterator = o
                content {
                  service_name = o.value.service_name
                  dynamic "method_selectors" {
                    for_each = toset(coalesce(o.value.method_selectors, []))
                    content {
                      method = method_selectors.key
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "ingress_policies" {
        for_each = each.value.spec.ingress_policies == null ? {} : {
          for k in each.value.spec.ingress_policies :
          k => lookup(var.ingress_policies, k, null)
          if contains(keys(var.ingress_policies), k)
        }
        iterator = policy
        content {
          dynamic "ingress_from" {
            for_each = policy.value.from == null ? [] : [""]
            content {
              identity_type = policy.value.from.identity_type
              identities    = policy.value.from.identities
              dynamic "sources" {
                for_each = toset(policy.value.from.access_levels)
                iterator = s
                content {
                  access_level = try(
                    google_access_context_manager_access_level.basic[s.value].id, s.value
                  )
                }
              }
              dynamic "sources" {
                for_each = toset(policy.value.from.resources)
                content {
                  resource = sources.key
                }
              }
            }
          }
          dynamic "ingress_to" {
            for_each = policy.value.to == null ? [] : [""]
            content {
              resources = policy.value.to.resources
              dynamic "operations" {
                for_each = toset(policy.value.to.operations)
                iterator = o
                content {
                  service_name = o.value.service_name
                  dynamic "method_selectors" {
                    for_each = toset(coalesce(o.value.method_selectors, []))
                    content {
                      method = method_selectors.value
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "vpc_accessible_services" {
        for_each = each.value.spec.vpc_accessible_services == null ? {} : { 1 = 1 }
        content {
          allowed_services   = each.value.spec.vpc_accessible_services.allowed_services
          enable_restriction = each.value.spec.vpc_accessible_services.enable_restriction
        }
      }

    }
  }
  dynamic "status" {
    for_each = each.value.status == null ? {} : { 1 = 1 }
    content {
      access_levels = (
        each.value.status.access_levels == null ? null : [
          for k in each.value.status.access_levels :
          try(google_access_context_manager_access_level.basic[k].id, k)
        ]
      )
      resources           = each.value.status.resources
      restricted_services = each.value.status.restricted_services

      dynamic "egress_policies" {
        for_each = each.value.spec.egress_policies == null ? {} : {
          for k in each.value.spec.egress_policies :
          k => lookup(var.egress_policies, k, null)
          if contains(keys(var.egress_policies), k)
        }
        iterator = policy
        content {
          dynamic "egress_from" {
            for_each = policy.value.from == null ? [] : [""]
            content {
              identity_type = policy.value.from.identity_type
              identities    = policy.value.from.identities
            }
          }
          dynamic "egress_to" {
            for_each = policy.value.to == null ? [] : [""]
            content {
              resources = policy.value.to.resources
              dynamic "operations" {
                for_each = toset(policy.value.to.operations)
                iterator = o
                content {
                  service_name = o.value.service_name
                  dynamic "method_selectors" {
                    for_each = toset(coalesce(o.value.method_selectors, []))
                    content {
                      method = method_selectors.key
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "ingress_policies" {
        for_each = each.value.spec.ingress_policies == null ? {} : {
          for k in each.value.spec.ingress_policies :
          k => lookup(var.ingress_policies, k, null)
          if contains(keys(var.ingress_policies), k)
        }
        iterator = policy
        content {
          dynamic "ingress_from" {
            for_each = policy.value.from == null ? [] : [""]
            content {
              identity_type = policy.value.from.identity_type
              identities    = policy.value.from.identities
              dynamic "sources" {
                for_each = toset(policy.value.from.access_levels)
                iterator = s
                content {
                  access_level = try(
                    google_access_context_manager_access_level.basic[s.value].id, s.value
                  )
                }
              }
              dynamic "sources" {
                for_each = toset(policy.value.from.resources)
                content {
                  resource = sources.key
                }
              }
            }
          }
          dynamic "ingress_to" {
            for_each = policy.value.to == null ? [] : [""]
            content {
              resources = policy.value.to.resources
              dynamic "operations" {
                for_each = toset(policy.value.to.operations)
                iterator = o
                content {
                  service_name = o.value.service_name
                  dynamic "method_selectors" {
                    for_each = toset(coalesce(o.value.method_selectors, []))
                    content {
                      method = method_selectors.value
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "vpc_accessible_services" {
        for_each = each.value.status.vpc_accessible_services == null ? {} : { 1 = 1 }
        content {
          allowed_services   = each.value.status.vpc_accessible_services.allowed_services
          enable_restriction = each.value.status.vpc_accessible_services.enable_restriction
        }
      }

    }
  }
  # lifecycle {
  #   ignore_changes = [spec[0].resources, status[0].resources]
  # }
  depends_on = [
    google_access_context_manager_access_policy.default,
    google_access_context_manager_access_level.basic
  ]
}
