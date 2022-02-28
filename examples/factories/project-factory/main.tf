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
  # internal structures for group IAM bindings
  _group_iam = {
    for r in local._group_iam_bindings : r => [
      for k, v in var.group_iam :
      "group:${k}" if try(index(v, r), null) != null
    ]
  }
  _group_iam_bindings = distinct(flatten(values(var.group_iam)))
  # internal structures for project service accounts IAM bindings
  _service_accounts_iam = {
    for r in local._service_accounts_iam_bindings : r => [
      for k, v in var.service_accounts :
      "serviceAccount:${k}@${var.project_id}.iam.gserviceaccount.com"
      if try(index(v, r), null) != null
    ]
  }
  _service_accounts_iam_bindings = distinct(flatten(
    values(var.service_accounts)
  ))
  # internal structures for project services
  _services = concat([
    "billingbudgets.googleapis.com",
    "essentialcontacts.googleapis.com"
    ],
    length(var.dns_zones) > 0 ? ["dns.googleapis.com"] : [],
    try(var.vpc.gke_setup, null) != null ? ["container.googleapis.com"] : [],
    var.vpc != null ? ["compute.googleapis.com"] : [],
  )
  # internal structures for service identity IAM bindings
  _service_identities_roles = distinct(flatten(values(var.service_identities_iam)))
  _service_identities_iam = {
    for role in local._service_identities_roles : role => [
      for service, roles in var.service_identities_iam :
      "serviceAccount:${module.project.service_accounts.robots[service]}"
      if contains(roles, role)
    ]
  }
  # internal structure for Shared VPC service project IAM bindings
  _vpc_subnet_bindings = (
    local.vpc.subnets_iam == null || local.vpc.host_project == null
    ? []
    : flatten([
      for subnet, members in local.vpc.subnets_iam : [
        for member in members : {
          region = split("/", subnet)[0]
          subnet = split("/", subnet)[1]
          member = member
        }
      ]
    ])
  )
  # structures for billing id
  billing_account_id = coalesce(
    var.billing_account_id, try(var.defaults.billing_account_id, "")
  )
  billing_alert = (
    var.billing_alert == null
    ? try(var.defaults.billing_alert, null)
    : var.billing_alert
  )
  # structure for essential contacts
  essential_contacts = concat(
    try(var.defaults.essential_contacts, []), var.essential_contacts
  )
  # structure that combines all authoritative IAM bindings
  iam = {
    for role in distinct(concat(
      keys(var.iam),
      keys(local._group_iam),
      keys(local._service_accounts_iam),
      keys(local._service_identities_iam),
    )) :
    role => concat(
      try(var.iam[role], []),
      try(local._group_iam[role], []),
      try(local._service_accounts_iam[role], []),
      try(local._service_identities_iam[role], []),
    )
  }
  # merge labels with defaults
  labels = merge(
    coalesce(var.labels, {}), coalesce(try(var.defaults.labels, {}), {})
  )
  # deduplicate services
  services = distinct(concat(var.services, local._services))
  # structures for Shared VPC resources in host project
  vpc = coalesce(var.vpc, {
    host_project = null, gke_setup = null, subnets_iam = null
  })
  vpc_cloudservices = (
    local.vpc_gke_service_agent ||
    contains(var.services, "compute.googleapis.com")
  )
  vpc_gke_security_admin = coalesce(
    try(local.vpc.gke_setup.enable_security_admin, null), false
  )
  vpc_gke_service_agent = coalesce(
    try(local.vpc.gke_setup.enable_host_service_agent, null), false
  )
  vpc_subnet_bindings = {
    for binding in local._vpc_subnet_bindings :
    "${binding.subnet}:${binding.member}" => binding
  }
}

module "billing-alert" {
  for_each              = local.billing_alert == null ? {} : { 1 = 1 }
  source                = "../../../modules/billing-budget"
  billing_account       = local.billing_account_id
  name                  = "${module.project.project_id} budget"
  amount                = local.billing_alert.amount
  thresholds            = local.billing_alert.thresholds
  credit_treatment      = local.billing_alert.credit_treatment
  notification_channels = var.defaults.notification_channels
  projects              = ["projects/${module.project.number}"]
  email_recipients = {
    project_id = module.project.project_id
    emails     = local.essential_contacts
  }
}

module "dns" {
  source          = "../../../modules/dns"
  for_each        = toset(var.dns_zones)
  project_id      = coalesce(local.vpc.host_project, module.project.project_id)
  type            = "private"
  name            = each.value
  domain          = "${each.value}.${var.defaults.environment_dns_zone}"
  client_networks = [var.defaults.shared_vpc_self_link]
}

module "project" {
  source                     = "../../../modules/project"
  billing_account            = local.billing_account_id
  name                       = var.project_id
  prefix                     = var.prefix
  contacts                   = { for c in local.essential_contacts : c => ["ALL"] }
  iam                        = local.iam
  labels                     = local.labels
  parent                     = var.folder_id
  policy_boolean             = try(var.org_policies.policy_boolean, {})
  policy_list                = try(var.org_policies.policy_list, {})
  service_encryption_key_ids = var.kms_service_agents
  services                   = local.services
  shared_vpc_service_config = var.vpc == null ? null : {
    host_project = local.vpc.host_project
    # these are non-authoritative
    service_identity_iam = {
      "roles/compute.networkUser" = compact([
        local.vpc_gke_service_agent ? "container-engine" : null,
        local.vpc_cloudservices ? "cloudservices" : null
      ])
      "roles/compute.securityAdmin" = compact([
        local.vpc_gke_security_admin ? "container-engine" : null,
      ])
      "roles/container.hostServiceAgentUser" = compact([
        local.vpc_gke_service_agent ? "container-engine" : null
      ])
    }
  }
}

module "service-accounts" {
  source     = "../../../modules/iam-service-account"
  for_each   = var.service_accounts
  name       = each.key
  project_id = module.project.project_id
}

resource "google_compute_subnetwork_iam_member" "default" {
  for_each   = local.vpc_subnet_bindings
  project    = local.vpc.host_project
  subnetwork = "projects/${local.vpc.host_project}/regions/${each.value.region}/subnetworks/${each.value.subnet}"
  region     = each.value.region
  role       = "roles/compute.networkUser"
  member     = each.value.member
}
