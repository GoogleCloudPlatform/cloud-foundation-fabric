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
  automation_resman_sa_iam = [
    "serviceAccount:${var.automation.service_accounts.resman}"
  ]
  automation_sas_iam = {
    for k, v in var.automation.service_accounts :
    k => v == null ? null : "serviceAccount:${v}"
  }
  branch_optional_sa_lists = {
    dp-dev   = compact([local.automation_sas_iam.dp-dev])
    dp-prod  = compact([local.automation_sas_iam.dp-prod])
    gke-dev  = compact([local.automation_sas_iam.gke-dev])
    gke-prod = compact([local.automation_sas_iam.gke-prod])
    pf-dev   = compact([local.automation_sas_iam.pf-dev])
    pf-prod  = compact([local.automation_sas_iam.pf-prod])
  }
  # derive identity pool names from identity providers for easy reference
  cicd_identity_pools = {
    for k, v in local.cicd_identity_providers :
    k => split("/providers/", v.name)[0]
  }
  cicd_identity_providers = coalesce(
    try(var.automation.federated_identity_providers, null), {}
  )
  cicd_repositories = {
    for k, v in coalesce(var.cicd_repositories, {}) : k => v
    if(
      v != null &&
      (
        try(v.type, null) == "sourcerepo"
        ||
        contains(
          keys(local.cicd_identity_providers),
          coalesce(try(v.identity_provider, null), ":")
        )
      ) &&
      fileexists("${path.module}/templates/workflow-${try(v.type, "")}.yaml")
    )
  }
  cicd_workflow_var_files = {
    stage_2 = [
      "0-bootstrap-tenant.auto.tfvars.json",
    ]
    stage_3 = [
      "0-bootstrap-tenant.auto.tfvars.json",
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
  groups = {
    for k, v in var.groups :
    k => v == null ? null : "${v}@${var.organization.domain}"
  }
  groups_iam = {
    for k, v in local.groups : k => v != null ? "group:${v}" : null
  }
}
