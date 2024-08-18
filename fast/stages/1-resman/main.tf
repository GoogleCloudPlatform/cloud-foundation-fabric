/**
 * Copyright 2024 Google LLC
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
  # leaving this here to document how to get self identity in a stage
  # automation_resman_sa = try(
  #   data.google_client_openid_userinfo.provider_identity[0].email, null
  # )
  # stage service accounts, used in top folders and outputs
  branch_service_accounts = {
    data-platform-dev      = try(module.branch-dp-dev-sa[0].email, null)
    data-platform-dev-r    = try(module.branch-dp-dev-r-sa[0].email, null)
    data-platform-prod     = try(module.branch-dp-prod-sa[0].email, null)
    data-platform-prod-r   = try(module.branch-dp-prod-r-sa[0].email, null)
    gcve-dev               = try(module.branch-gcve-dev-sa[0].email, null)
    gcve-dev-r             = try(module.branch-gcve-dev-r-sa[0].email, null)
    gcve-prod              = try(module.branch-gcve-prod-sa[0].email, null)
    gcve-prod-r            = try(module.branch-gcve-prod-r-sa[0].email, null)
    gke-dev                = try(module.branch-gke-dev-sa[0].email, null)
    gke-dev-r              = try(module.branch-gke-dev-r-sa[0].email, null)
    gke-prod               = try(module.branch-gke-prod-sa[0].email, null)
    gke-prod-r             = try(module.branch-gke-prod-r-sa[0].email, null)
    nsec                   = module.branch-nsec-sa.email
    nsec-r                 = module.branch-nsec-r-sa.email
    networking             = module.branch-network-sa.email
    networking-r           = module.branch-network-r-sa.email
    project-factory        = try(module.branch-pf-sa.email, null)
    project-factory-r      = try(module.branch-pf-r-sa.email, null)
    project-factory-dev    = try(module.branch-pf-dev-sa.email, null)
    project-factory-dev-r  = try(module.branch-pf-dev-r-sa.email, null)
    project-factory-prod   = try(module.branch-pf-prod-sa.email, null)
    project-factory-prod-r = try(module.branch-pf-prod-r-sa.email, null)
    sandbox                = try(module.branch-sandbox-sa[0].email, null)
    security               = module.branch-security-sa.email
    security-r             = module.branch-security-r-sa.email
  }
  # normalize CI/CD repositories
  cicd_repositories = {
    for k, v in coalesce(var.cicd_repositories, {}) : k => v
    if(
      v != null &&
      contains(
        keys(local.identity_providers),
        coalesce(try(v.identity_provider, null), ":")
      ) &&
      fileexists("${path.module}/templates/workflow-${try(v.type, "")}.yaml")
    )
  }
  cicd_workflow_var_files = {
    stage_2 = [
      "0-bootstrap.auto.tfvars.json",
      "1-resman.auto.tfvars.json",
      "0-globals.auto.tfvars.json"
    ]
    stage_3 = [
      "0-bootstrap.auto.tfvars.json",
      "1-resman.auto.tfvars.json",
      "0-globals.auto.tfvars.json",
      "2-networking.auto.tfvars.json",
      "2-security.auto.tfvars.json"
    ]
  }
  custom_roles = coalesce(var.custom_roles, {})
  gcs_storage_class = (
    length(split("-", var.locations.gcs)) < 2
    ? "MULTI_REGIONAL"
    : "REGIONAL"
  )
  identity_providers = coalesce(
    try(var.automation.federated_identity_providers, null), {}
  )
  principals = {
    for k, v in var.groups : k => (
      can(regex("^[a-zA-Z]+:", v))
      ? v
      : "group:${v}@${var.organization.domain}"
    )
  }
  root_node = (
    var.root_node == null
    ? "organizations/${var.organization.id}"
    : var.root_node
  )
  tag_keys = (
    var.root_node == null
    ? module.organization[0].tag_keys
    : module.automation-project[0].tag_keys
  )
  tag_root = (
    var.root_node == null
    ? var.organization.id
    : var.automation.project_id
  )
  tag_values = (
    var.root_node == null
    ? module.organization[0].tag_values
    : module.automation-project[0].tag_values
  )
}

# data "google_client_openid_userinfo" "provider_identity" {
#   count = length(local.cicd_repositories) > 0 ? 1 : 0
# }
