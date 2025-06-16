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
  templates_flat = flatten([
    for project_key, project_data in module.projects.projects :
    [
      for template_config in try(project_data.automation.templates, []) :
      {
        project_key     = project_key
        project_data    = project_data
        template_config = template_config
      } if try(project_data.automation.templates, null) != null
    ]
  ])
  workflow_templates = {
    for t in local.templates_flat :
    t.project_key => {
      content = templatefile(
        "${path.module}/templates/workflow-${
          var.automation.federated_identity_providers[
            t.template_config.workload_identity_provider
          ].issuer
        }.yaml",
        {
          identity_provider = var.automation.federated_identity_providers[t.template_config.workload_identity_provider].name
          outputs_bucket    = t.project_data.automation.outputs_bucket
          service_accounts = {
            apply = t.project_data.automation.service_accounts[t.template_config.workflow.apply.service_account]
            plan  = t.project_data.automation.service_accounts[t.template_config.workflow.plan.service_account]
          }
          workflow_name = "Project ${t.project_key}"
          tf_providers_files = {
            apply = "${t.project_key}-${t.template_config.workflow.apply.provider_file}-provider.tf"
            plan  = "${t.project_key}-${t.template_config.workflow.plan.provider_file}-provider.tf"
          }
          audiences = try(
            var.automation.federated_identity_providers[t.template_config.workload_identity_provider].audiences,
            null
          )
        }
      )
      filename_suffix = "${
        var.automation.federated_identity_providers[
          t.template_config.workload_identity_provider
        ]
      .issuer}-workflow.yaml"
      outputs_bucket = t.project_data.automation.outputs_bucket
    } if try(t.template_config.workflow, null) != null
  }
  provider_files = {
    for v in flatten([
      for t in local.templates_flat :
      [
        for pf in try(t.template_config.provider_files, []) :
        {
          key             = "${t.project_key}-${pf.service_account}-provider"
          bucket          = t.project_data.automation.bucket
          outputs_bucket  = t.project_data.automation.outputs_bucket
          project_id      = t.project_data.automation.project
          project_number  = local.project_numbers_by_id[t.project_data.automation.project]
          service_account = t.project_data.automation.service_accounts[pf.service_account]
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
  filename        = "${pathexpand(var.outputs_location)}/workflows/${each.key}-${each.value.filename_suffix}"
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
  filename        = "${pathexpand(var.outputs_location)}/providers/${each.key}.tf"
  content         = templatefile("${path.module}/templates/providers.tf.tpl", each.value)
}