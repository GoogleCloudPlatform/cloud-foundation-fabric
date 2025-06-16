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

# tfdoc:file:description This file defines local values for selecting projects with CI/CD configuration and generating workflow templates for each project.

locals {
  cicd_projects = {
    for k, v in module.projects.projects :
    k => v
    if try(v.automation.cicd_config[0].provider, null) != null
  }
  cicd_workflow_templates_github = {
    for k, p in local.cicd_projects :
    k =>
    templatefile(
      "${path.module}/templates/workflow-github.yaml",
      {
        identity_provider = var.automation.federated_identity_providers[
          p.automation.cicd_config[0].provider
        ].name
        outputs_bucket = p.automation.outputs_bucket
        service_accounts = {
          apply = p.automation.service_accounts["cicd-rw"]
          plan  = try(p.automation.service_accounts["cicd-ro"], p.automation.service_accounts["cicd-rw"])
        }
        stage_name = "Project ${k}"
        tf_providers_files = try(p.automation.cicd_config[0].tf_providers_files, {
          apply = "${k}-rw-providers.tf"
          plan  = "${k}-ro-providers.tf"
        })
      }
    ) if var.automation.federated_identity_providers[p.automation.cicd_config[0].provider].issuer == "github"
  }
  cicd_workflow_templates_gitlab = {
    for k, p in local.cicd_projects :
    k =>
    templatefile(
      "${path.module}/templates/workflow-gitlab.yaml",
      {
        audiences = var.automation.federated_identity_providers[
          p.automation.cicd_config[0].provider
        ].audiences
        identity_provider = var.automation.federated_identity_providers[
          p.automation.cicd_config[0].provider
        ].name
        outputs_bucket = p.automation.outputs_bucket
        service_accounts = {
          apply = p.automation.service_accounts["cicd-rw"]
          plan  = try(p.automation.service_accounts["cicd-ro"], p.automation.service_accounts["cicd-rw"])
        }
        tf_providers_files = try(p.automation.cicd_config[0].tf_providers_files, {
          apply = "${k}-rw-providers.tf"
          plan  = "${k}-ro-providers.tf"
        })
      }
    ) if var.automation.federated_identity_providers[p.automation.cicd_config[0].provider].issuer == "gitlab"
  }
  cicd_workflow_templates = merge(
    local.cicd_workflow_templates_github,
    local.cicd_workflow_templates_gitlab
  )
  project_provider_data = flatten([
    for k, v in module.projects.projects :
    [
      for sk, sv in try(v.automation.service_accounts, {}) :
      {
        key             = "${k}-${replace(sk, "/", "-")}"
        bucket          = v.automation.bucket
        outputs_bucket  = v.automation.outputs_bucket
        project_id      = v.project_id
        project_number  = v.number
        service_account = sv
        is_cicd         = strcontains(sk, "cicd-")
      } if try(v.automation.bucket, null) != null
    ]
  ])
}

resource "local_file" "workflows" {
  for_each        = var.outputs_location == null ? {} : local.cicd_workflow_templates
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/workflows/${each.key}-${var.automation.federated_identity_providers[local.cicd_projects[each.key].automation.cicd_config[0].provider].issuer}-workflow.yaml"
  content         = each.value
}

resource "google_storage_bucket_object" "workflows" {
  for_each = local.cicd_workflow_templates
  bucket   = local.cicd_projects[each.key].automation.outputs_bucket
  name     = "workflows/${each.key}-${var.automation.federated_identity_providers[local.cicd_projects[each.key].automation.cicd_config[0].provider].issuer}-workflow.yaml"
  content  = each.value
}

resource "google_storage_bucket_object" "providers" {
  for_each = { for v in local.project_provider_data : v.key => v if !v.is_cicd }
  bucket   = each.value.outputs_bucket
  name     = "providers/${replace(each.key, "-cicd", "")}-providers.tf"
  content  = templatefile("${path.module}/templates/providers.tf.tpl", each.value)
}

resource "local_file" "providers" {
  for_each        = var.outputs_location == null ? {} : { for v in local.project_provider_data : v.key => v if !v.is_cicd }
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/providers/${replace(each.key, "-cicd", "")}-providers.tf"
  content         = templatefile("${path.module}/templates/providers.tf.tpl", each.value)
}
