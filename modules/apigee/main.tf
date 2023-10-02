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

locals {
  org_id   = try(google_apigee_organization.organization[0].id, "organizations/${var.project_id}")
  org_name = try(google_apigee_organization.organization[0].name, var.project_id)
}

resource "google_apigee_organization" "organization" {
  count                                = var.organization == null ? 0 : 1
  analytics_region                     = var.organization.analytics_region
  project_id                           = var.project_id
  authorized_network                   = var.organization.authorized_network
  billing_type                         = var.organization.billing_type
  runtime_type                         = var.organization.runtime_type
  runtime_database_encryption_key_name = var.organization.database_encryption_key
  retention                            = var.organization.retention
  disable_vpc_peering                  = var.organization.disable_vpc_peering
}

resource "google_apigee_envgroup" "envgroups" {
  for_each  = var.envgroups
  name      = each.key
  hostnames = each.value
  org_id    = local.org_id
}

resource "google_apigee_environment" "environments" {
  for_each        = var.environments
  name            = each.key
  display_name    = each.value.display_name
  description     = each.value.description
  deployment_type = each.value.deployment_type
  api_proxy_type  = each.value.api_proxy_type
  dynamic "node_config" {
    for_each = try(each.value.node_config, null) != null ? [""] : []
    content {
      min_node_count = each.value.node_config.min_node_count
      max_node_count = each.value.node_config.max_node_count
    }
  }
  org_id = local.org_id
  lifecycle {
    ignore_changes = [
      node_config["current_aggregate_node_count"]
    ]
  }
}

resource "google_apigee_envgroup_attachment" "envgroup_attachments" {
  for_each = merge(concat([for k1, v1 in var.environments : {
    for v2 in coalesce(v1.envgroups, []) : "${k1}-${v2}" => {
      environment = k1
      envgroup    = v2
    }
  }])...)
  envgroup_id = "${local.org_id}/envgroups/${each.value.envgroup}"
  environment = google_apigee_environment.environments[each.value.environment].name
  depends_on  = [google_apigee_envgroup.envgroups]
}

resource "google_apigee_environment_iam_binding" "binding" {
  for_each = merge(concat([for k1, v1 in var.environments : {
    for k2, v2 in coalesce(v1.iam, {}) : "${k1}-${k2}" => {
      environment = "${k1}"
      role        = k2
      members     = v2
    }
  }])...)
  org_id  = local.org_id
  env_id  = google_apigee_environment.environments[each.value.environment].name
  role    = each.value.role
  members = each.value.members
}

resource "google_apigee_instance" "instances" {
  for_each     = var.instances
  name         = coalesce(each.value.name, "instance-${each.key}")
  display_name = each.value.display_name
  description  = each.value.description
  location     = each.key
  org_id       = local.org_id
  ip_range = (
    compact([each.value.runtime_ip_cidr_range, each.value.troubleshooting_ip_cidr_range]) == []
    ? null
    : join(",", compact([each.value.runtime_ip_cidr_range, each.value.troubleshooting_ip_cidr_range]))
  )
  disk_encryption_key_name = each.value.disk_encryption_key
  consumer_accept_list     = each.value.consumer_accept_list
}

resource "google_apigee_nat_address" "apigee_nat" {
  for_each = {
    for k, v in var.instances :
    k => google_apigee_instance.instances[k].id
    if v.enable_nat
  }
  name        = each.key
  instance_id = each.value
}

resource "google_apigee_instance_attachment" "instance_attachments" {
  for_each = merge(concat([for k1, v1 in var.instances : {
    for v2 in coalesce(v1.environments, []) :
    "${k1}-${v2}" => {
      instance    = k1
      environment = v2
    }
  }])...)
  instance_id = google_apigee_instance.instances[each.value.instance].id
  environment = each.value.environment
  depends_on  = [google_apigee_environment.environments]
}

resource "google_apigee_endpoint_attachment" "endpoint_attachments" {
  for_each               = var.endpoint_attachments
  org_id                 = local.org_id
  endpoint_attachment_id = each.key
  location               = each.value.region
  service_attachment     = each.value.service_attachment
}

resource "google_apigee_addons_config" "addons_config" {
  for_each = toset(var.addons_config == null ? [] : [""])
  org      = local.org_name
  addons_config {
    advanced_api_ops_config {
      enabled = var.addons_config.advanced_api_ops
    }
    api_security_config {
      enabled = var.addons_config.api_security
    }
    connectors_platform_config {
      enabled = var.addons_config.connectors_platform
    }
    integration_config {
      enabled = var.addons_config.integration
    }
    monetization_config {
      enabled = var.addons_config.monetization
    }
  }
}
