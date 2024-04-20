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
  _factory_data = (
    var.factories_config.rules != null
    ? file(pathexpand(var.factories_config.rules))
    : "{}"
  )
  _factory_rules = yamldecode(local._factory_data)
  factory_rules = {
    for k, v in local._factory_rules : k => {
      dns_name = v.dns_name
      behavior = lookup(v, "behavior", "bypassResponsePolicy")
      local_data = {
        for kk, vv in lookup(v, "local_data", {}) :
        kk => merge({ ttl = null, rrdatas = [] }, vv)
      }
    }
  }
  policy_name = (
    var.policy_create
    ? google_dns_response_policy.default[0].response_policy_name
    : var.name
  )
}

resource "google_dns_response_policy" "default" {
  provider             = google-beta
  count                = var.policy_create ? 1 : 0
  project              = var.project_id
  description          = var.description
  response_policy_name = var.name
  dynamic "networks" {
    for_each = var.networks
    content {
      network_url = networks.value
    }
  }
  dynamic "gke_clusters" {
    for_each = var.clusters
    content {
      gke_cluster_name = gke_clusters.value
    }
  }
}

resource "google_dns_response_policy_rule" "default" {
  provider        = google-beta
  for_each        = merge(local.factory_rules, var.rules)
  project         = var.project_id
  response_policy = local.policy_name
  rule_name       = each.key
  dns_name        = each.value.dns_name
  behavior = (
    length(each.value.local_data) == 0 ? each.value.behavior : null
  )
  dynamic "local_data" {
    for_each = length(each.value.local_data) == 0 ? [] : [""]
    content {
      dynamic "local_datas" {
        for_each = each.value.local_data
        iterator = data
        content {
          # setting name to something different seems to have no effect
          # so we comply with the console UI and set it to the rule dns name
          # name    = split(" ", data.key)[1]
          # type    = split(" ", data.key)[0]
          name    = each.value.dns_name
          type    = data.key
          ttl     = data.value.ttl
          rrdatas = data.value.rrdatas
        }
      }
    }
  }
}
