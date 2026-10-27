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

# tfdoc:file:description IAM Unified Access Policies and bindings.

locals {
  # Flatten all principals referenced across rules so legacy IAM v1
  # prefixes (user:, group:, serviceAccount:, domain:) can be resolved
  # through context and normalized to IAM v3 principal URIs once.
  _raw_principals = distinct(flatten([
    for k, v in var.access_policies : [
      for rk, rv in v.rules : concat(rv.principals, rv.excluded_principals)
    ]
  ]))

  _resolved_principals = {
    for p in local._raw_principals :
    p => lookup(local.ctx.iam_principals, p, p)
  }

  _normalized_principals = {
    for p, rp in local._resolved_principals : p => (
      startswith(rp, "user:")
      ? "principal://goog/subject/${trimprefix(rp, "user:")}"
      : startswith(rp, "group:")
      ? "principalSet://goog/group/${trimprefix(rp, "group:")}"
      : startswith(rp, "serviceAccount:")
      ? "principal://iam.googleapis.com/projects/-/serviceAccounts/${trimprefix(rp, "serviceAccount:")}"
      : startswith(rp, "domain:")
      ? "principalSet://goog/cloudIdentityCustomerId/${trimprefix(rp, "domain:")}"
      : contains(["allUsers", "allAuthenticatedUsers"], rp)
      ? "principalSet://goog/public:all"
      : rp
    )
  }

  _registry_cel_default = (
    length(local.registry_locations) == 1
    ? "destination.is_registered == true && destination.agent_registry.location == '${local.registry_locations[0]}'"
    : "destination.is_registered == true && destination.agent_registry.location in [${join(", ", [for l in local.registry_locations : "'${l}'"])}]"
  )

  _access_policy_rules = {
    for k, v in var.access_policies : k => {
      for rk, rv in v.rules : rk => merge(rv, {
        custom_cel = (
          rv.condition == null
          ? null
          : templatestring(rv.condition, var.context.condition_vars)
        )
        excluded_principals = [
          for p in rv.excluded_principals : local._normalized_principals[p]
        ]
        location = (
          rv.location == null
          ? local.location
          : lookup(local.ctx.locations, rv.location, rv.location)
        )
        principals = [
          for p in rv.principals : local._normalized_principals[p]
        ]
        registry_location = (
          rv.location == null
          ? null
          : lookup(local.ctx.locations, rv.location, rv.location)
        )
      })
    }
  }

  access_policies_create = {
    for k, v in var.access_policies : k => merge(v, {
      rules = {
        for rk, rv in local._access_policy_rules[k] : rk => merge(rv, {
          expression = join(" && ", compact([
            rv.registry ? (
              rv.registry_location != null
              ? "destination.is_registered == true && destination.agent_registry.location == '${rv.registry_location}'"
              : local._registry_cel_default
            ) : null,
            rv.agent_id != null ? (
              startswith(rv.agent_id, "projects/") || startswith(rv.agent_id, "/projects/")
              ? "destination.agent_registry.agent.name == '${rv.agent_id}'"
              : "destination.agent_registry.agent.name == 'projects/${local.project_id}/locations/${rv.location}/agents/${rv.agent_id}'"
            ) : null,
            rv.endpoint_id != null ? (
              startswith(rv.endpoint_id, "projects/") || startswith(rv.endpoint_id, "/projects/")
              ? "destination.agent_registry.endpoint.name == '${rv.endpoint_id}'"
              : "destination.agent_registry.endpoint.name == 'projects/${local.project_id}/locations/${rv.location}/endpoints/${rv.endpoint_id}'"
            ) : null,
            rv.mcp_server_id != null ? (
              startswith(rv.mcp_server_id, "projects/") || startswith(rv.mcp_server_id, "/projects/")
              ? "destination.agent_registry.mcp_server.name == '${rv.mcp_server_id}'"
              : "destination.agent_registry.mcp_server.name == 'projects/${local.project_id}/locations/${rv.location}/mcpServers/${rv.mcp_server_id}'"
            ) : null,
            rv.custom_cel
          ]))
        })
      }
    }) if v.policy_reuse == null
  }

  access_policy_bindings = {
    for k, v in var.access_policies : k => merge(v, {
      binding_id = coalesce(v.binding_id, k)
      policy = (
        v.policy_reuse == null
        ? "projects/${local.project_id}/locations/global/accessPolicies/${google_iam_project_access_policy.default[k].access_policy_id}"
        : lookup(local.ctx.access_policies, v.policy_reuse, v.policy_reuse)
      )
      target_resource = (
        v.target_resource == "project"
        ? "//cloudresourcemanager.googleapis.com/projects/${local.project_id}"
        : v.target_resource == "gateway"
        ? "//networkservices.googleapis.com/${google_network_services_agent_gateway.default.id}"
        : v.target_resource
      )
    }) if v.bind
  }
}

resource "google_iam_project_access_policy" "default" {
  provider         = google-beta
  for_each         = local.access_policies_create
  project          = local.project_id
  location         = "global"
  access_policy_id = each.key
  display_name     = each.value.display_name
  annotations      = each.value.annotations

  details {
    dynamic "rules" {
      for_each = each.value.rules
      content {
        description         = rules.value.description
        effect              = rules.value.effect
        principals          = rules.value.principals
        excluded_principals = rules.value.excluded_principals

        operation {
          permissions          = rules.value.permissions
          excluded_permissions = rules.value.excluded_permissions
        }

        dynamic "conditions" {
          for_each = rules.value.expression == "" ? [] : [""]
          content {
            service    = rules.value.condition_service
            expression = rules.value.expression
          }
        }
      }
    }
  }
}

resource "google_iam_projects_policy_binding" "default" {
  provider          = google-beta
  for_each          = local.access_policy_bindings
  project           = local.project_id
  location          = "global"
  policy_binding_id = each.value.binding_id
  policy_kind       = "ACCESS"
  policy            = each.value.policy
  display_name      = each.value.display_name
  annotations       = each.value.annotations

  target {
    resource = each.value.target_resource
  }

  dynamic "condition" {
    for_each = each.value.binding_condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.binding_condition.expression, var.context.condition_vars
      )
      title       = each.value.binding_condition.title
      description = each.value.binding_condition.description
      location    = each.value.binding_condition.location
    }
  }
}
