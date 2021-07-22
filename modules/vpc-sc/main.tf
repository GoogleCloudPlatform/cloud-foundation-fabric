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

locals {
  access_policy_name = (
    var.access_policy_create
    ? try(google_access_context_manager_access_policy.default[0].name, null)
    : var.access_policy_name
  )

  standard_perimeters = {
    for key, value in var.perimeters :
    key => value if value.type == "PERIMETER_TYPE_REGULAR"
  }

  bridge_perimeters = {
    for key, value in var.perimeters :
    key => value if value.type == "PERIMETER_TYPE_BRIDGE"
  }

  perimeter_access_levels_enforced    = try(transpose(var.access_level_perimeters.enforced), null)
  perimeter_access_levels_dry_run     = try(transpose(var.access_level_perimeters.dry_run), null)
  perimeter_ingress_policies_enforced = try(transpose(var.ingress_policies_perimeters.enforced), null)
  perimeter_ingress_policies_dry_run  = try(transpose(var.ingress_policies_perimeters.dry_run), null)
  perimeter_egress_policies_enforced  = try(transpose(var.egress_policies_perimeters.enforced), null)
  perimeter_egress_policies_dry_run   = try(transpose(var.egress_policies_perimeters.dry_run), null)
}

resource "google_access_context_manager_access_policy" "default" {
  count  = var.access_policy_create ? 1 : 0
  parent = var.organization_id
  title  = var.access_policy_title == null ? "${var.organization_id}-title" : var.access_policy_title
}

resource "google_access_context_manager_access_level" "default" {
  for_each = var.access_levels
  parent   = "accessPolicies/${local.access_policy_name}"
  name     = "accessPolicies/${local.access_policy_name}/accessLevels/${each.key}"
  title    = each.key

  dynamic "basic" {
    for_each = try(toset(each.value.conditions), [])
    iterator = condition

    content {
      combining_function = try(each.value.combining_function, null)
      conditions {
        ip_subnetworks         = try(condition.value.ip_subnetworks, null)
        required_access_levels = try(condition.value.required_access_levels, null)
        members                = try(condition.value.members, null)
        negate                 = try(condition.value.negate, null)
        regions                = try(condition.value.regions, null)
      }
    }
  }
}

resource "google_access_context_manager_service_perimeter" "standard" {
  for_each       = local.standard_perimeters
  parent         = "accessPolicies/${local.access_policy_name}"
  description    = "Terraform managed."
  name           = "accessPolicies/${local.access_policy_name}/servicePerimeters/${each.key}"
  title          = each.key
  perimeter_type = each.value.type

  # Enforced mode configuration
  dynamic "status" {
    for_each = each.value.enforced_config != null ? [""] : []

    content {
      resources = formatlist(
        "projects/%s", try(lookup(var.perimeter_projects, each.key, {}).enforced, [])
      )
      restricted_services = each.value.enforced_config.restricted_services
      access_levels = formatlist(
        "accessPolicies/${local.access_policy_name}/accessLevels/%s",
        try(lookup(local.perimeter_access_levels_enforced, each.key, []), [])
      )

      dynamic "vpc_accessible_services" {
        for_each = try(length(each.value.enforced_config.vpc_accessible_services) != 0 ? [""] : [], [])

        content {
          enable_restriction = true
          allowed_services   = each.value.enforced_config.vpc_accessible_services
        }
      }

      dynamic "egress_policies" {
        for_each = try(local.perimeter_egress_policies_enforced[each.key] != null ? local.perimeter_egress_policies_enforced[each.key] : [], [])

        content {
          dynamic "egress_from" {
            for_each = try(var.egress_policies[egress_policies.value].egress_from != null ? [""] : [], [])

            content {
              identity_type = try(var.egress_policies[egress_policies.value].egress_from.identity_type, null)
              identities    = try(var.egress_policies[egress_policies.value].egress_from.identities, null)
            }
          }
          dynamic "egress_to" {
            for_each = try(var.egress_policies[egress_policies.value].egress_to != null ? [""] : [], [])

            content {
              resources = try(var.egress_policies[egress_policies.value].egress_to.resources, null)

              dynamic "operations" {
                for_each = try(var.egress_policies[egress_policies.value].egress_to.operations, [])

                content {
                  service_name = try(operations.key, null)

                  dynamic "method_selectors" {
                    for_each = try(operations.value, [])

                    content {
                      method     = try(method_selectors.value.method, null)
                      permission = try(method_selectors.value.permission, null)
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "ingress_policies" {
        for_each = try(local.perimeter_ingress_policies_enforced[each.key] != null ? local.perimeter_ingress_policies_enforced[each.key] : [], [])

        content {
          dynamic "ingress_from" {
            for_each = try(var.ingress_policies[ingress_policies.value].ingress_from != null ? [""] : [], [])

            content {
              identity_type = try(var.ingress_policies[ingress_policies.value].ingress_from.identity_type, null)
              identities    = try(var.ingress_policies[ingress_policies.value].ingress_from.identities, null)

              dynamic "sources" {
                for_each = toset(try([var.ingress_policies[ingress_policies.value].ingress_from.sources], []))

                content {
                  access_level = try(sources.value.access_level, null)
                  resource     = try(sources.value.resource, null)
                }
              }
            }
          }
          dynamic "ingress_to" {
            for_each = try(var.ingress_policies[ingress_policies.value].ingress_to != null ? [""] : [], [])

            content {
              resources = try(var.ingress_policies[ingress_policies.value].ingress_to.resources, null)

              dynamic "operations" {
                for_each = try(var.ingress_policies[ingress_policies.value].ingress_to.operations, [])

                content {
                  service_name = try(operations.key, null)

                  dynamic "method_selectors" {
                    for_each = try(operations.value, [])

                    content {
                      method     = try(method_selectors.value.method, null)
                      permission = try(method_selectors.value.permission, null)
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

  # Dry run mode configuration
  use_explicit_dry_run_spec = each.value.dry_run_config != null ? true : false
  dynamic "spec" {
    for_each = each.value.dry_run_config != null ? [""] : []

    content {
      resources = formatlist(
        "projects/%s", try(lookup(var.perimeter_projects, each.key, {}).dry_run, [])
      )
      restricted_services = try(each.value.dry_run_config.restricted_services, null)
      access_levels = formatlist(
        "accessPolicies/${local.access_policy_name}/accessLevels/%s",
        try(lookup(local.perimeter_access_levels_dry_run, each.key, []), [])
      )

      dynamic "vpc_accessible_services" {
        for_each = try(length(each.value.dry_run_config.vpc_accessible_services) != 0 ? [""] : [], [])

        content {
          enable_restriction = true
          allowed_services   = try(each.value.dry_run_config.vpc_accessible_services, null)
        }
      }

      dynamic "egress_policies" {
        for_each = try(local.perimeter_egress_policies_dry_run[each.key] != null ? local.perimeter_egress_policies_dry_run[each.key] : [], [])

        content {
          dynamic "egress_from" {
            for_each = try(var.egress_policies[egress_policies.value].egress_from != null ? [""] : [], [])

            content {
              identity_type = try(var.egress_policies[egress_policies.value].egress_from.identity_type, null)
              identities    = try(var.egress_policies[egress_policies.value].egress_from.identities, null)
            }
          }
          dynamic "egress_to" {
            for_each = try(var.egress_policies[egress_policies.value].egress_to != null ? [""] : [], [])

            content {
              resources = try(var.egress_policies[egress_policies.value].egress_to.resources, null)

              dynamic "operations" {
                for_each = try(var.egress_policies[egress_policies.value].egress_to.operations, [])

                content {
                  service_name = try(operations.key, null)

                  dynamic "method_selectors" {
                    for_each = try(operations.value, [])

                    content {
                      method     = try(method_selectors.value.method, null)
                      permission = try(method_selectors.value.permission, null)
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "ingress_policies" {
        for_each = try(local.perimeter_ingress_policies_dry_run[each.key] != null ? local.perimeter_ingress_policies_dry_run[each.key] : [], [])

        content {
          dynamic "ingress_from" {
            for_each = try(var.ingress_policies[ingress_policies.value].ingress_from != null ? [""] : [], [])

            content {
              identity_type = try(var.ingress_policies[ingress_policies.value].ingress_from.identity_type, null)
              identities    = try(var.ingress_policies[ingress_policies.value].ingress_from.identities, null)

              dynamic "sources" {
                for_each = toset(try([var.ingress_policies[ingress_policies.value].ingress_from.sources], []))

                content {
                  access_level = try(sources.value.access_level, null)
                  resource     = try(sources.value.resource, null)
                }
              }
            }
          }
          dynamic "ingress_to" {
            for_each = try(var.ingress_policies[ingress_policies.value].ingress_to != null ? [""] : [], [])

            content {
              resources = try(var.ingress_policies[ingress_policies.value].ingress_to.resources, null)

              dynamic "operations" {
                for_each = try(var.ingress_policies[ingress_policies.value].ingress_to.operations, [])

                content {
                  service_name = try(operations.key, null)

                  dynamic "method_selectors" {
                    for_each = try(operations.value, [])

                    content {
                      method     = try(method_selectors.value.method, null)
                      permission = try(method_selectors.value.permission, null)
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

  # Uncomment if used alongside `google_access_context_manager_service_perimeter_resource`,
  # so they don't fight over which resources should be in the policy.
  # lifecycle {
  #   ignore_changes = [status[0].resources]
  # }

  depends_on = [
    google_access_context_manager_access_level.default,
  ]
}

resource "google_access_context_manager_service_perimeter" "bridge" {
  for_each       = local.bridge_perimeters
  parent         = "accessPolicies/${local.access_policy_name}"
  description    = "Terraform managed."
  name           = "accessPolicies/${local.access_policy_name}/servicePerimeters/${each.key}"
  title          = each.key
  perimeter_type = each.value.type

  # Enforced mode configuration
  dynamic "status" {
    for_each = try(lookup(var.perimeter_projects, each.key, {}).enforced, []) != null ? [""] : []

    content {
      resources = formatlist("projects/%s", try(lookup(var.perimeter_projects, each.key, {}).enforced, []))
    }
  }

  # Dry run mode configuration
  dynamic "spec" {
    for_each = try(lookup(var.perimeter_projects, each.key, {}).dry_run, []) != null ? [""] : []

    content {
      resources = formatlist("projects/%s", try(lookup(var.perimeter_projects, each.key, {}).dry_run, []))
    }
  }

  # Uncomment if used alongside `google_access_context_manager_service_perimeter_resource`,
  # so they don't fight over which resources should be in the policy.
  # lifecycle {
  #   ignore_changes = [status[0].resources]
  # }

  depends_on = [
    google_access_context_manager_service_perimeter.standard,
    google_access_context_manager_access_level.default,
  ]
}
