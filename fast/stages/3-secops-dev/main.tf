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

module "secops-tenant" {
  source = "../../project-templates/secops-tenant"
  project_id = var.secops_project_ids[var.stage.environment]
  secops_group_principals = var.secops_group_principals
  secops_iam = var.secops_iam
  secops_tenant_config = var.secops_tenant_config
  secops_data_rbac_config = var.secops_data_rbac_config
  project_create_config = var.project_create_config
  regions = var.regions
  workspace_integration_config = var.workspace_integration_config
}

module "secops-rules" {
  source     = "../../../modules/secops-rules"
  project_id = var.secops_project_ids[var.stage.environment]
  tenant_config = {
    region      = var.secops_tenant_config.region
    customer_id = var.secops_tenant_config.customer_id
  }
  factories_config = var.factories_config
}
