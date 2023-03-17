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

# tfdoc:file:description Project factory.

# TODO: allow identities to no have the domain part and append org domain if needed

locals {
  _all_vpc_hosts = {
    for k, v in var.host_project_ids :
    "fast:${k}" => v
  }
  _default_services = [
    "billingbudgets.googleapis.com",
    "essentialcontacts.googleapis.com",
    "orgpolicy.googleapis.com",
  ]
  _projects_raw = {
    for f in fileset(var.data_path, "**/*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.data_path}/${f}"))
  }
  projects = {
    for k, v in local._projects_raw :
    k => merge(v, {
      # project attributes
      name             = lookup(v, "id", basename(k))
      descriptive_name = lookup(v, "descriptive_name", null)
      billing_account  = lookup(v, "billing_account_id", var.billing_account.id)
      #parent           = lookup(local._all_parents, v.parent, v.parent)
      parent = v.parent
      labels = lookup(v, "labels", null)
      # iam and policies
      iam = {
        for role, members in lookup(v, "iam", {}) :
        role => [
          for member in members :
          endswith(member, "@") ? "${member}${var.organization.domain}" : member
        ]
      }
      iam_additive = {
        for role, members in lookup(v, "iam_additive", {}) :
        role => [
          for member in members :
          endswith(member, "@") ? "${member}${var.organization.domain}" : member
        ]
      }
      group_iam = {
        for role, groups in lookup(v, "group_iam", {}) :
        role => [
          for group in groups :
          endswith(group, "@") ? "group:${group}${var.organization.domain}" : "group:${group}"
        ]
      }
      org_policies = lookup(v, "org_policies", null)
      tag_bindings = {
        for k2, v2 in lookup(v, "tag_bindings", {}) :
        k2 => lookup(var.tag_values, v2, v2)
      }
      # management
      services = distinct(concat(lookup(v, "services", []), local._default_services))
      contacts = { for x in lookup(v, "contacts", []) : x => ["ALL"] }
      # billing budget
      budget = lookup(v, "budget", null)
      # networking
      shared_vpc_service_config = lookup(v, "vpc", null) == null ? null : {
        host_project         = lookup(local._all_vpc_hosts, v.vpc.host_project, v.vpc.host_project)
        service_identity_iam = lookup(v.vpc, "service_identity_iam", null)
      }
    })
  }
  subnet_bindings = flatten([
    for k, v in local._projects_raw : [
      for subnet, members in try(v.vpc.subnets_iam, {}) : [
        for member in members : {
          host_project = lookup(local._all_vpc_hosts, v.vpc.host_project, v.vpc.host_project),
          region       = split("/", subnet)[0],
          subnet       = split("/", subnet)[1],
          member       = endswith(member, "@") ? "${member}${var.organization.domain}" : member
        }
      ]
    ]
  ])
}

module "projects" {
  source                    = "../../../../modules/project"
  for_each                  = local.projects
  billing_account           = each.value.billing_account
  parent                    = each.value.parent
  prefix                    = var.prefix
  name                      = each.value.name
  descriptive_name          = each.value.descriptive_name
  labels                    = each.value.labels
  services                  = each.value.services
  iam                       = each.value.iam
  iam_additive              = each.value.iam_additive
  group_iam                 = each.value.group_iam
  org_policies              = each.value.org_policies
  contacts                  = each.value.contacts
  shared_vpc_service_config = each.value.shared_vpc_service_config
  tag_bindings              = each.value.tag_bindings
}

resource "google_compute_subnetwork_iam_member" "default" {
  for_each   = { for b in local.subnet_bindings : join("/", values(b)) => b }
  project    = each.value.host_project
  subnetwork = "projects/${each.value.host_project}/regions/${each.value.region}/subnetworks/${each.value.subnet}"
  region     = each.value.region
  role       = "roles/compute.networkUser"
  member     = each.value.member
}
