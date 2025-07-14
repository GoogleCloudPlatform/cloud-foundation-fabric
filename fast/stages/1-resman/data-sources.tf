/**
 * Copyright 2025 Google LLC
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

# tfdoc:file:description Terraform remote state data-sources.

locals {
  bootstrap_outputs = try(coalesce(
    data.tfe_outputs.bootstrap["tfe"].nonsensitive_values,
    data.terraform_remote_state.bootstrap_s3["s3"].outputs,
    data.terraform_remote_state.bootstrap_gcs["gcs"].outputs,
  ), {})
  automation = coalesce(
    try(local.bootstrap_outputs.tfvars.automation, null),
    var.automation
  )
  billing_account = coalesce(
    try(local.bootstrap_outputs.tfvars_globals.billing_account, null),
    var.billing_account
  )
  custom_roles = coalesce(
    try(local.bootstrap_outputs.tfvars.custom_roles, null),
    var.custom_roles
  )
  environments = coalesce(
    try(local.bootstrap_outputs.tfvars_globals.environments, null),
    var.environments
  )
  groups = coalesce(
    try(local.bootstrap_outputs.tfvars_globals.groups, null),
    var.groups
  )
  locations = coalesce(
    try(local.bootstrap_outputs.tfvars_globals.locations, null),
    var.locations
  )
  logging = coalesce(
    try(local.bootstrap_outputs.tfvars.logging, null),
    var.logging
  )
  organization = coalesce(
    try(local.bootstrap_outputs.tfvars_globals.organization, null),
    var.organization
  )
  org_policy_tags_output = coalesce(
    try(local.bootstrap_outputs.tfvars.org_policy_tags, null),
    var.org_policy_tags
  )
  prefix = coalesce(
    try(local.bootstrap_outputs.tfvars_globals.prefix, null),
    var.prefix
  )
  #   root_node = coalesce(
  #     try(local.bootstrap_outputs.root_node, null),
  #     var.root_node
  #   )
}

data "tfe_outputs" "bootstrap" {
  for_each     = var.remote_output.bootstrap.tfe != null ? { tfe = var.remote_output.bootstrap.tfe } : {}
  organization = each.value.organization
  workspace    = each.value.workspace
}

data "terraform_remote_state" "bootstrap_s3" {
  for_each = var.remote_output.bootstrap.state.s3 != null ? { s3 = var.remote_output.bootstrap.state.s3 } : {}
  backend  = "s3"
  config = {
    bucket     = each.value.bucket
    key        = each.value.key
    kms_key_id = each.value.kms_key_id
    region     = each.value.region
    role_arn   = each.value.role_arn
  }
}

data "terraform_remote_state" "bootstrap_gcs" {
  for_each = var.remote_output.bootstrap.state.gcs != null ? { gcs = var.remote_output.bootstrap.state.gcs } : {}
  backend  = "gcs"
  config = {
    bucket                      = each.value.bucket
    impersonate_service_account = each.value.impersonate_service_account
    kms_encryption_key          = each.value.kms_encryption_key
    prefix                      = each.value.prefix
  }
}
