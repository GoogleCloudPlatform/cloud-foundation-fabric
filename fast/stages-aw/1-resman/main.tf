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
  # convenience flags that express where billing account resides
  automation_resman_sa = try(
    data.google_client_openid_userinfo.provider_identity[0].email, null
  )
  automation_resman_sa_iam = (
    local.automation_resman_sa == null
    ? []
    : ["serviceAccount:${local.automation_resman_sa}"]
  )
  # service accounts that receive additional grants on networking/security
  branch_optional_sa_lists = {
    dp-dev    = compact([try(module.branch-dp-dev-sa[0].iam_email, "")])
    dp-prod   = compact([try(module.branch-dp-prod-sa[0].iam_email, "")])
    gcve-dev  = compact([try(module.branch-gcve-dev-sa[0].iam_email, "")])
    gcve-prod = compact([try(module.branch-gcve-prod-sa[0].iam_email, "")])
    gke-dev   = compact([try(module.branch-gke-dev-sa[0].iam_email, "")])
    gke-prod  = compact([try(module.branch-gke-prod-sa[0].iam_email, "")])
    pf-dev    = compact([try(module.branch-pf-dev-sa[0].iam_email, "")])
    pf-prod   = compact([try(module.branch-pf-prod-sa[0].iam_email, "")])
  }
  branch_optional_r_sa_lists = {
    dp-dev    = compact([try(module.branch-dp-dev-r-sa[0].iam_email, "")])
    dp-prod   = compact([try(module.branch-dp-prod-r-sa[0].iam_email, "")])
    gcve-dev  = compact([try(module.branch-gcve-dev-r-sa[0].iam_email, "")])
    gcve-prod = compact([try(module.branch-gcve-prod-r-sa[0].iam_email, "")])
    gke-dev   = compact([try(module.branch-gke-dev-r-sa[0].iam_email, "")])
    gke-prod  = compact([try(module.branch-gke-prod-r-sa[0].iam_email, "")])
    pf-dev    = compact([try(module.branch-pf-dev-r-sa[0].iam_email, "")])
    pf-prod   = compact([try(module.branch-pf-prod-r-sa[0].iam_email, "")])
  }
  # normalize CI/CD repositories
  cicd_repositories = {
    for k, v in coalesce(var.cicd_repositories, {}) : k => v
    if(
      v != null &&
      (
        try(v.type, null) == "sourcerepo"
        ||
        contains(
          keys(local.identity_providers),
          coalesce(try(v.identity_provider, null), ":")
        )
      ) &&
      fileexists("${path.module}/templates/workflow-${try(v.type, "")}.yaml")
    )
  }
  team_cicd_repositories = {
    for k, v in coalesce(var.team_folders, {}) : k => v
    if(
      v != null &&
      (
        try(v.cicd.type, null) == "sourcerepo"
        ||
        contains(
          keys(local.identity_providers),
          coalesce(try(v.cicd.identity_provider, null), ":")
        )
      ) &&
      fileexists("${path.module}/templates/workflow-${try(v.cicd.type, "")}.yaml")
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
}

data "google_client_openid_userinfo" "provider_identity" {
  count = length(local.cicd_repositories) > 0 ? 1 : 0
}
