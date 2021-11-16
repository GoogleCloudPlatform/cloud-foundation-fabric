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
  public_projects     = { for projectId, project in var.projects : projectId => lookup(project, "allowPublicServices", false) == true ? project : null }
  charging_code_label = lookup(var.config, "chargingCodeLabel", "charging-code")
  gitlab_projects     = { for projectId, project in var.projects : projectId => project if length(keys(lookup(project, "gitlab", {}))) > 1 }
  auto_create_network = lookup(var.config, "autoCreateNetwork", {})
}

# Fetch existing group IDs
module "get-groups" {
  source = "../get-groups/"

  environments = lookup(var.config, "environments", {})
  config       = var.config
}

# Create main GCP project
module "project" {
  for_each = var.projects
  source   = "../project/"

  environments = each.value.environments

  project_id        = lower(each.value.projectId)
  custom_project_id = lookup(each.value, "customProjectId", "")
  project_id_format = var.config.projectIdFormat
  display_name      = each.value.displayName
  owner             = lookup(each.value, "owner", "")
  owners            = lookup(each.value, "owners", [])
  default_labels    = lookup(var.config, "labels", {})
  labels            = merge(lookup(each.value, "labels", {}), zipmap([local.charging_code_label], [each.value.chargingCode]))
  metadata          = lookup(var.config, "defaultProjectMetadata", {})

  organization_id     = var.config.organizationId
  folder              = each.value.folder
  folder_ids          = var.config.folders[each.value.folder]
  shared_vpc_projects = var.config.sharedVpcProjects[each.value.folder]
  billing_account     = var.config.billingAccount

  budget                      = lookup(each.value, "budget", lookup(var.config, "defaultBudget", null))
  budget_alert_pubsub_topics  = var.config.budgetAlertTopics[each.value.folder]
  budget_alert_spent_percents = lookup(each.value, "budgetAlertSpentPercents", var.config.budgetAlertSpentPercents)

  activate_apis       = concat(var.config.defaultApis, lookup(each.value, "additionalApis", []))
  auto_create_network = lookup(local.auto_create_network, each.value.folder, {})

  domain                       = var.config.domain
  essential_contact_categories = lookup(var.config, "essentialContactsOwnerCategories", [])

  is_public_project    = lookup(each.value, "allowPublicServices", false)
  boolean_org_policies = lookup(lookup(var.config, "publicServicesOrgPolicies", {}), "booleanPolicies", {})
  list_org_policies    = lookup(lookup(var.config, "publicServicesOrgPolicies", {}), "listPolicies", {})

  vpcsc_perimeters = var.config.vpcServiceControlPerimeters[each.value.folder]
}

# Set up project groups
module "groups" {
  for_each = var.projects
  source   = "../groups/"

  all_groups = module.get-groups.groups

  environments = each.value.environments

  domain           = var.config.domain
  customer_id      = var.config.cloudIdentityCustomerId
  owner            = lookup(each.value, "owner", "")
  owners           = lookup(each.value, "owners", [])
  project_id       = lower(each.value.projectId)
  project_ids_full = module.project[lower(each.value.projectId)].project_ids
  folder           = each.value.folder

  group_format      = lookup(var.config, "projectGroupFormat", "%project%-%group%-%env%")
  main_group        = lookup(var.config, "projectMainGroup", "all")
  owner_group       = lookup(var.config, "projectOwnerGroup", "")
  shared_vpc_groups = var.config.sharedVpcGroups[each.value.folder]
  groups            = lookup(var.config, "setProjectGroups", lookup(each.value, "team", {}))
  service_accounts = {
    "project" = { for env in each.value.environments : env => module.project[lower(each.value.projectId)].service_accounts[env] }
    "compute" = { for env in each.value.environments : env => format("%d-compute@developer.gserviceaccount.com", module.project[lower(each.value.projectId)].project_numbers[env]) }
  }
  groups_permissions = var.config.projectGroups

  additional_roles        = lookup(each.value, "roles", {})
  additional_roles_config = lookup(var.config, "projectGroupsRoles", {})
  additional_iam_roles    = lookup(each.value, "additionalIamRoles", {})

  only_add_permissions = lookup(var.config, "onlyProjectGroupIamPermissions", false)
}

# Connect project to correct monitoring Metrics Scope
module "monitoring" {
  for_each = var.projects
  source   = "../monitoring"

  all_groups = module.get-groups.groups

  quota_project = var.config.seedProject
  environments  = each.value.environments

  domain      = var.config.domain
  customer_id = var.config.cloudIdentityCustomerId

  project_ids_full    = module.project[lower(each.value.projectId)].project_ids
  monitoring_projects = var.config.monitoringProjects[each.value.folder]
  monitoring_groups   = var.config.monitoringGroups[each.value.folder]

  project_groups = module.groups[each.key].project_group_keys

  only_add_project = lookup(var.config, "onlyProjectGroupIamPermissions", false)
}

# Set up Serverless access
module "serverless" {
  for_each = var.projects
  source   = "../serverless/"

  all_groups = module.get-groups.groups

  environments = each.value.environments

  domain           = var.config.domain
  customer_id      = var.config.cloudIdentityCustomerId
  project_id       = lower(each.value.projectId)
  project_ids_full = module.project[lower(each.value.projectId)].project_ids
  project_numbers  = module.project[lower(each.value.projectId)].project_numbers

  serverless_groups           = lookup(lookup(var.config, "sharedVpcServerlessGroups", {}), each.value.folder, {})
  sa_groups                   = module.sa-group[each.key].sa_group_keys
  serverless_service_accounts = lookup(var.config, "serverlessServiceAccounts", [])

  only_add_project = lookup(var.config, "onlyProjectGroupIamPermissions", false)
}

# Manage project service account
module "default-project-sa" {
  for_each = var.projects
  source   = "../default-sa/"

  environments = each.value.environments

  project_ids_full = module.project[lower(each.value.projectId)].project_ids
  service_accounts = module.project[lower(each.value.projectId)].service_accounts

  project_permissions = lookup(var.config, "defaultProjectSAPrivileges", [])
}

# Manage project default Compute Engine service account
module "default-compute-sa" {
  for_each = var.projects
  source   = "../default-sa/"

  environments = each.value.environments

  project_ids_full = module.project[lower(each.value.projectId)].project_ids
  service_accounts = { for env in each.value.environments : env => format("%d-compute@developer.gserviceaccount.com", module.project[lower(each.value.projectId)].project_numbers[env]) }

  project_permissions = var.config.defaultComputeSAPrivileges
}

# Manage Service Account group
module "sa-group" {
  for_each = var.projects
  source   = "../sa-group/"

  all_groups = module.get-groups.groups

  environments = each.value.environments

  domain           = var.config.domain
  customer_id      = var.config.cloudIdentityCustomerId
  project_id       = lower(each.value.projectId)
  project_ids_full = module.project[lower(each.value.projectId)].project_ids
  project_numbers  = module.project[lower(each.value.projectId)].project_numbers

  group_format            = lookup(var.config, "projectServiceAccountGroupFormat", "%project%-serviceaccounts-%env%")
  shared_vpc_groups       = var.config.sharedVpcGroups[each.value.folder]
  service_account         = lookup(var.config, "terraformServiceAccount", "")
  service_accounts        = lookup(var.config, "projectServiceAccountGroupMembers", ["project-service-account@%project%.iam.gserviceaccount.com"])
  add_to_shared_vpc_group = lookup(var.config, "projectServiceAccountGroupJoinSharedVpc", false)

  api_service_accounts = lookup(var.config, "perApiServiceAccounts", {})
  activated_apis       = concat(var.config.defaultApis, lookup(each.value, "additionalApis", []))

  only_add_permissions = lookup(var.config, "onlyProjectGroupIamPermissions", false)
}

# Create and manage privileged service accounts
module "service-accounts" {
  for_each = var.projects
  source   = "../service-accounts/"

  environments     = each.value.environments
  project_ids_full = module.project[lower(each.value.projectId)].project_ids
  sa_groups        = module.sa-group[each.key].sa_group_id
  project_groups   = module.groups[each.key].project_group_keys

  service_accounts      = lookup(each.value, "serviceAccounts", [])
  service_account_roles = lookup(var.config, "serviceAccountRoles", {})

  only_add_permissions = lookup(var.config, "onlyProjectGroupIamPermissions", false)
}

# Manage Identity-Aware Proxy settings
module "iap" {
  for_each = var.projects

  source = "../iap/"

  environments = each.value.environments

  project_id       = lower(each.value.projectId)
  project_ids_full = module.project[lower(each.value.projectId)].project_ids
  domain           = var.config.domain
  customer_id      = var.config.cloudIdentityCustomerId

  title = lookup(lookup(each.value, "iap", {}), "title", "")

  email_format    = lookup(var.config, "iapSupportGroupFormat", "iap-support-%project%@%domain%")
  service_account = lookup(var.config, "terraformServiceAccount", "")
}

# Manage recommendations reports for projects
module "recommendations" {
  source = "../recommendations/"

  projects              = var.projects
  recommendations_topic = lookup(lookup(var.config, "recommendationsReports", {}), "pubsubTopic", "")

  scheduler_project  = var.config.seedProject
  scheduler_region   = lookup(lookup(var.config, "recommendationsReports", {}), "schedulerRegion", "")
  scheduler_cron     = lookup(lookup(var.config, "recommendationsReports", {}), "schedulerSchedule", "")
  scheduler_timezone = lookup(lookup(var.config, "recommendationsReports", {}), "schedulerTimezone", "")
}
