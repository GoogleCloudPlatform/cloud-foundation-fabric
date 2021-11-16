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
  project_id = replace(
    replace(
      replace(var.project_id_format, "%id%", var.project_id),
    "%folder%", lower(var.folder)),
  "%random%", random_id.random_project_id_suffix.hex)
  owner          = lower(replace(replace(var.owner, "@", "_at_"), ".", "-"))
  owners         = join("---", [for owner in var.owners : lower(replace(replace(owner, "@", "_at_"), ".", "-"))])
  default_labels = { for k, v in var.default_labels : k => replace(replace(replace(v, "%id%", var.project_id), "%folder%", lower(var.folder)), "%owner%", local.owner) }

  bool_policies = var.is_public_project ? var.boolean_org_policies : {}
  list_policies = var.is_public_project ? {
    for constraint, value in var.list_org_policies : constraint => {
      inherit_from_parent = null
      suggested_value     = null
      status              = true
      values              = value
    }
  } : {}
}

resource "random_id" "random_project_id_suffix" {
  byte_length = 2
}

module "project-factory" {
  for_each = toset(var.environments)

  source = "../../../../modules/project/"

  descriptive_name = format("%s - %s", upper(each.value), var.display_name)
  name             = var.custom_project_id != "" ? var.custom_project_id : replace(local.project_id, "%env%", each.value)
  parent           = var.folder_ids[each.value] != "" ? format("folders/%d", var.folder_ids[each.value]) : format("organizations/%d", var.organization_id)

  billing_account     = var.billing_account
  auto_create_network = lookup(var.auto_create_network, each.value, false)

  labels = merge(var.labels, merge(local.default_labels, zipmap([var.environment_label], [each.value])))

  services = var.activate_apis

  shared_vpc_service_config = {
    attach       = var.shared_vpc_projects[each.value] != "" ? true : false
    host_project = var.shared_vpc_projects[each.value]
  }

  policy_boolean = local.bool_policies
  policy_list    = local.list_policies

  service_perimeter_standard = var.vpcsc_perimeters[each.value] != "" ? var.vpcsc_perimeters[each.value] : null
}

resource "google_project_default_service_accounts" "deprivilege" {
  for_each = toset(var.environments)
  project  = module.project-factory[each.value].project_id

  action         = "DEPRIVILEGE"
  restore_policy = "REVERT"
}

locals {
  budgets = var.budget != null ? [for env in var.environments : env if lookup(var.budget, env, null) != null] : []
}

module "budget" {
  for_each = toset(local.budgets)

  source          = "../../../../modules/billing-budget/"
  billing_account = var.billing_account
  name            = format("%s (%s)", var.display_name, upper(each.value))

  amount = var.budget[each.value]
  thresholds = {
    current    = var.budget_alert_spent_percents
    forecasted = []
  }
  projects = [
    format("projects/%d", module.project-factory[each.value].number)
  ]
  pubsub_topic = lookup(var.budget_alert_pubsub_topics, var.environments[count.index], null)
}

module "project-service-account" {
  for_each = toset(var.environments)

  source     = "../../../../modules/iam-service-account/"
  project_id = module.project-factory[each.value].project_id

  name = var.project_sa_name

  generate_key = false
}

locals {
  metadata = [for env in var.environments : { for mk, mv in var.metadata : "${env}-${mk}" => {
    env   = env
    name  = mk
    value = mv
  } }]
}

resource "google_compute_project_metadata_item" "project_metadata" {
  for_each = merge(local.metadata...)

  project = module.project-factory[each.value.env].project_id
  key     = each.value.name
  value   = each.value.value
}

locals {
  ec_owners  = length(var.owners) > 0 ? [for owner in var.owners : format("%s%s", owner, var.domain != "" ? format("@%s", var.domain) : "")] : [format("%s%s", var.owner, var.domain != "" ? format("@%s", var.domain) : "")]
  ec         = setproduct(var.environments, local.ec_owners)
  ec_foreach = { for k in local.ec : format("%s-%s", k[0], k[1]) => [k[0], k[1]] }
}

resource "google_essential_contacts_contact" "essential_contacts" {
  for_each = local.ec_foreach

  parent                              = format("projects/%s", module.project-factory[each.value[0]].project_id)
  email                               = each.value[1]
  language_tag                        = "en"
  notification_category_subscriptions = var.essential_contact_categories
}
