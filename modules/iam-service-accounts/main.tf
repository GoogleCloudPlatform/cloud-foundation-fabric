/**
 * Copyright 2019 Google LLC
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
  iam_pairs = {
    for pair in setproduct(var.names, var.iam_roles) :
    "${pair.0}-${pair.1}" => { name = pair.0, role = pair.1 }
  }
  iam_billing_pairs = flatten([
    for entity, roles in var.iam_billing_roles : [
      for role in roles : [
        for name in var.names : { entity = entity, role = role, name = name }
      ]
    ]
  ])
  iam_folder_pairs = flatten([
    for entity, roles in var.iam_folder_roles : [
      for role in roles : [
        for name in var.names : { entity = entity, role = role, name = name }
      ]
    ]
  ])
  iam_organization_pairs = flatten([
    for entity, roles in var.iam_organization_roles : [
      for role in roles : [
        for name in var.names : { entity = entity, role = role, name = name }
      ]
    ]
  ])
  iam_project_pairs = flatten([
    for entity, roles in var.iam_project_roles : [
      for role in roles : [
        for name in var.names : { entity = entity, role = role, name = name }
      ]
    ]
  ])
  iam_storage_pairs = flatten([
    for entity, roles in var.iam_storage_roles : [
      for role in roles : [
        for name in var.names : { entity = entity, role = role, name = name }
      ]
    ]
  ])
  keys = (
    var.generate_keys
    ? {
      for name in var.names :
      name => lookup(google_service_account_key.keys, name, null)
    }
    : {}
  )
  prefix = (
    var.prefix != ""
    ? "${var.prefix}-"
    : ""
  )
  resource = (
    length(var.names) > 0
    ? lookup(local.resources, var.names[0], null)
    : null
  )
  resource_iam_emails = {
    for name, resource in local.resources :
    name => "serviceAccount:${resource.email}"
  }
  resources = {
    for name in var.names :
    name => lookup(google_service_account.service_accounts, name, null)
  }
}

resource "google_service_account" "service_accounts" {
  for_each     = toset(var.names)
  project      = var.project_id
  account_id   = "${local.prefix}${lower(each.value)}"
  display_name = "Terraform-managed."
}

resource "google_service_account_key" "keys" {
  for_each           = var.generate_keys ? toset(var.names) : toset([])
  service_account_id = google_service_account.service_accounts[each.value].email
}

resource "google_service_account_iam_binding" "sa-roles" {
  for_each           = local.iam_pairs
  service_account_id = google_service_account.service_accounts[each.value.name].name
  role               = each.value.role
  members            = lookup(var.iam_members, each.value.role, [])
}

resource "google_billing_account_iam_member" "roles" {
  for_each = {
    for pair in local.iam_billing_pairs :
    "${pair.name}-${pair.entity}-${pair.role}" => pair
  }
  billing_account_id = each.value.entity
  role               = each.value.role
  member             = local.resource_iam_emails[each.value.name]
}

resource "google_folder_iam_member" "roles" {
  for_each = {
    for pair in local.iam_folder_pairs :
    "${pair.name}-${pair.entity}-${pair.role}" => pair
  }
  folder = each.value.entity
  role   = each.value.role
  member = local.resource_iam_emails[each.value.name]
}

resource "google_organization_iam_member" "roles" {
  for_each = {
    for pair in local.iam_organization_pairs :
    "${pair.name}-${pair.entity}-${pair.role}" => pair
  }
  org_id = each.value.entity
  role   = each.value.role
  member = local.resource_iam_emails[each.value.name]
}

resource "google_project_iam_member" "project-roles" {
  for_each = {
    for pair in local.iam_project_pairs :
    "${pair.name}-${pair.entity}-${pair.role}" => pair
  }
  project = each.value.entity
  role    = each.value.role
  member  = local.resource_iam_emails[each.value.name]
}

resource "google_storage_bucket_iam_member" "bucket-roles" {
  for_each = {
    for pair in local.iam_storage_pairs :
    "${pair.name}-${pair.entity}-${pair.role}" => pair
  }
  bucket = each.value.entity
  role   = each.value.role
  member = local.resource_iam_emails[each.value.name]
}

# TODO(ludoo): link from README
# ref: https://cloud.google.com/vpc/docs/shared-vpc
