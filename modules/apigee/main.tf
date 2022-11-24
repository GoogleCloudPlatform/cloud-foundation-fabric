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

locals {
  org_id       = try(google_apigee_organization.organization[0].id, "organizations/${var.project_id}")
  envgroups    = coalesce(var.envgroups, {})
  environments = coalesce(var.environments, {})
  instances    = coalesce(var.instances, {})
}

resource "google_apigee_organization" "organization" {
  count                                = var.organization == null ? 0 : 1
  analytics_region                     = var.organization.analytics_region
  project_id                           = var.project_id
  authorized_network                   = var.organization.authorized_network
  billing_type                         = var.organization.billing_type
  runtime_type                         = var.organization.runtime_type
  runtime_database_encryption_key_name = var.organization.database_encryption_key
}

resource "google_apigee_envgroup" "envgroups" {
  for_each  = local.envgroups
  name      = each.key
  hostnames = each.value
  org_id    = local.org_id
}

resource "google_apigee_environment" "environments" {
  for_each     = local.environments
  name         = each.key
  display_name = each.value.display_name
  description  = each.value.description
  dynamic "node_config" {
    for_each = try(each.value.node_config, null) != null ? [""] : []
    content {
      min_node_count               = node_config.min_node_count
      max_node_count               = node_config.max_node_count
      current_aggregate_node_count = node_config.current_aggregate_node_count
    }
  }
  org_id = local.org_id
}

resource "google_apigee_envgroup_attachment" "envgroup_attachments" {
  for_each = merge(concat([for k1, v1 in local.environments : {
    for v2 in v1.envgroups : "${k1}-${v2}" => {
      environment = k1
      envgroup    = v2
    }
  }])...)
  envgroup_id = try(google_apigee_envgroup.envgroups[each.value.envgroup].id, each.value.envgroup)
  environment = google_apigee_environment.environments[each.value.environment].name
}

resource "google_apigee_environment_iam_binding" "binding" {
  for_each = merge(concat([for k1, v1 in local.environments : {
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
  for_each                 = local.instances
  name                     = each.key
  display_name             = each.value.display_name
  description              = each.value.description
  location                 = each.value.region
  org_id                   = local.org_id
  ip_range                 = each.value.psa_ip_cidr_range
  disk_encryption_key_name = each.value.disk_encryption_key
  consumer_accept_list     = each.value.consumer_accept_list
}

resource "google_apigee_instance_attachment" "instance_attachments" {
  for_each = merge(concat([for k1, v1 in local.instances : {
    for v2 in v1.environments :
    "${k1}-${v2}" => {
      instance    = k1
      environment = v2
    }
  }])...)
  instance_id = google_apigee_instance.instances[each.value.instance].id
  environment = try(google_apigee_environment.environments[each.value.environment].name,
  "${local.org_id}/environments/${each.value.environment}")

}
