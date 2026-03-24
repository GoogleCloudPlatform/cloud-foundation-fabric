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

# tfdoc:file:description Routers factory.

locals {
  ctx_routers = {
    ids   = { for k, v in google_compute_router.default : k => v.id }
    names = { for k, v in google_compute_router.default : k => v.name }
  }
  router_configs = merge(flatten([
    for vpc_key, vpc_config in local.vpcs : [
      for router_key, router_config in try(vpc_config.routers, {}) : {
        "${vpc_key}/${router_key}" = merge(router_config, {
          name              = replace("${vpc_key}/${router_key}", "/", "-")
          vpc_self_link     = vpc_key
          project_id        = vpc_config.project_id
          custom_advertise  = try(router_config.custom_advertise, {})
          advertise_mode    = try(router_config.custom_advertise != null, false) ? "CUSTOM" : "DEFAULT"
          advertised_groups = try(router_config.custom_advertise.all_subnets, false) ? ["ALL_SUBNETS"] : []
          keepalive         = try(router_config.keepalive, null)
          asn               = try(router_config.asn, null)
          route_policies    = try(router_config.route_policies, {})
        })
      }
    ]
  ])...)

  router_route_policies = merge(flatten([
    for router_key, router_config in local.router_configs : [
      for policy_key, policy_config in router_config.route_policies : {
        "${router_key}/${policy_key}" = merge(policy_config, {
          router_name = replace(router_key, "/", "-")
          project     = lookup(local.ctx_projects.project_ids, replace(router_config.project_id, "$project_ids:", ""), router_config.project_id)
          region      = lookup(local.ctx.locations, replace(router_config.region, "$locations:", ""), router_config.region)
          name        = policy_key
        })
      }
    ]
  ])...)
}

resource "google_compute_router" "default" {
  for_each = local.router_configs
  name     = replace(each.key, "/", "-")
  project = lookup(
    local.ctx_projects.project_ids,
    replace(each.value.project_id, "$project_ids:", ""),
    each.value.project_id
  )
  region = lookup(
    local.ctx.locations,
    replace(each.value.region, "$locations:", ""),
    each.value.region
  )
  network = lookup(
    local.ctx_vpcs.self_links,
    each.value.vpc_self_link,
    each.value.vpc_self_link
  )
  bgp {
    advertise_mode    = each.value.advertise_mode
    advertised_groups = each.value.advertised_groups
    dynamic "advertised_ip_ranges" {
      for_each = try(each.value.custom_advertise.ip_ranges, {})
      iterator = range
      content {
        range       = range.key
        description = range.value
      }
    }
    keepalive_interval = each.value.keepalive
    asn                = each.value.asn
  }
}

resource "google_compute_router_route_policy" "default" {
  for_each = local.router_route_policies
  project  = each.value.project
  region   = each.value.region
  router   = each.value.router_name
  name     = each.value.name
  type     = each.value.type == "IMPORT" ? "ROUTE_POLICY_TYPE_IMPORT" : each.value.type == "EXPORT" ? "ROUTE_POLICY_TYPE_EXPORT" : null

  dynamic "terms" {
    for_each = try(each.value.terms, [])
    content {
      priority = terms.value.priority
      match {
        expression  = terms.value.match.expression
        title       = try(terms.value.match.title, null)
        description = try(terms.value.match.description, null)
        location    = try(terms.value.match.location, null)
      }
      actions {
        expression  = terms.value.actions.expression
        title       = try(terms.value.actions.title, null)
        description = try(terms.value.actions.description, null)
        location    = try(terms.value.actions.location, null)
      }
    }
  }

  lifecycle {
    precondition {
      condition     = contains(["IMPORT", "EXPORT"], each.value.type)
      error_message = "Route policy type must be either 'IMPORT' or 'EXPORT'."
    }
    precondition {
      condition     = length(try(each.value.terms, [])) == length(distinct([for t in try(each.value.terms, []) : t.priority]))
      error_message = "Route policy term priorities must be unique."
    }
    precondition {
      condition     = alltrue([for t in try(each.value.terms, []) : t.priority >= 0 && t.priority < 231])
      error_message = "Route policy term priority must be between 0 (inclusive) and 231 (exclusive)."
    }
  }

  depends_on = [google_compute_router.default]
}
