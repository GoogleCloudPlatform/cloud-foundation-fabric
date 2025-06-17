/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# tfdoc:file:description This file defines local values for selecting projects with CI/CD configuration and generating workflow templates for each project based on the `automation.templates` attribute.

locals {
  project_numbers_by_id = {
    for p in module.projects.projects : p.project_id => p.number
  }
  cicd_projects = {
    for k, v in module.projects.projects : k => v
    if try(v.automation.templates, null) != null
  }
  workflow_templates = {
    for key, p in local.cicd_projects :
    key => {
      content = templatefile(
        "${path.module}/templates/workflow-${var.automation.federated_identity_providers[
          p.automation.cicd_config.identity_provider
        ].issuer}.yaml",
        {
          identity_provider = var.automation.federated_identity_providers[
            p.automation.cicd_config.identity_provider
          ].name
          outputs_bucket = p.automation.outputs_bucket
          service_accounts = {
            apply = p.automation.service_accounts[p.automation.templates.workflow.apply.service_account]
            plan  = p.automation.service_accounts[p.automation.templates.workflow.plan.service_account]
          }
          workflow_name = "Project ${key}"
          tf_providers_files = {
            apply = "${key}-${p.automation.cicd_config.impersonations[
              p.automation.templates.workflow.apply.service_account
            ]}-provider.tf"
            plan = "${key}-${p.automation.cicd_config.impersonations[
              p.automation.templates.workflow.plan.service_account
            ]}-provider.tf"
          }
          audiences = try(
            var.automation.federated_identity_providers[
              p.automation.cicd_config.identity_provider
            ].audiences,
            null
          )
        }
      )
      filename_suffix = "${var.automation.federated_identity_providers[
        p.automation.cicd_config.identity_provider
      ].issuer}-workflow.yaml"
      outputs_bucket = p.automation.outputs_bucket
    } if try(p.automation.templates.workflow, null) != null
  }
  provider_files = {
    for v in flatten([
      for key, p in local.cicd_projects : [
        for pf in try(p.automation.templates.provider_files, []) : {
          key             = "${key}-${pf.service_account}-provider"
          bucket          = p.automation.bucket
          outputs_bucket  = p.automation.outputs_bucket
          project_id      = p.automation.project
          project_number  = local.project_numbers_by_id[p.automation.project]
          service_account = p.automation.service_accounts[pf.service_account]
        }
      ]
    ]) : v.key => v
  }
}

resource "google_storage_bucket_object" "workflows" {
  for_each = local.workflow_templates
  bucket   = each.value.outputs_bucket
  name     = "workflows/${each.key}-${each.value.filename_suffix}"
  content  = each.value.content
}

resource "local_file" "workflows" {
  for_each        = var.outputs_location == null ? {} : local.workflow_templates
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/workflows/${var.stage_name}/${each.key}-${each.value.filename_suffix}"
  content         = each.value.content
}

resource "google_storage_bucket_object" "providers" {
  for_each = local.provider_files
  bucket   = each.value.outputs_bucket
  name     = "providers/${each.key}.tf"
  content  = templatefile("${path.module}/templates/providers.tf.tpl", each.value)
}

resource "local_file" "providers" {
  for_each        = var.outputs_location == null ? {} : local.provider_files
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/providers/${var.stage_name}/${each.key}.tf"
  content         = templatefile("${path.module}/templates/providers.tf.tpl", each.value)
}