/**
 * Copyright 2024 Google LLC
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

locals {
  _project_numbers = { for p in module.projects : p.name => p.number }
  cicd_projects    = { for k, v in local.projects : k => v if try(v.automation.templates.workflow, null) != null }
  project_outputs_bucket_names = merge(
    { for k, v in local._outputs_buckets_to_create : v.project_key => module.automation-bucket[k].name },
    { for k, v in data.google_storage_bucket.outputs_existing : k => v.name }
  )
  workflow_templates = {
    for v in flatten([
      for project_key, p in local.cicd_projects : [
        for workflow_key, workflow_config in p.automation.templates.workflow : {
          project_key : project_key,
          workflow_key : workflow_key,
          template_path : workflow_config.template,
          template_vars : try(workflow_config.vars, {}),
          outputs_bucket : local.project_outputs_bucket_names[project_key]
        }
      ]
    ]) : "${v.project_key}-${v.workflow_key}" => v
  }
}

output "automation_service_accounts" {
  description = "Automation service account emails, keyed by project/sa_name."
  value       = { for k, v in module.automation-service-accounts : k => v.email }
}

output "buckets" {
  description = "Bucket names."
  value = {
    for k, v in module.buckets : k => v.name
  }
}

output "folders" {
  description = "Folder ids."
  value       = local.hierarchy
}

output "projects" {
  description = "Created projects."
  value = {
    for k, v in module.projects : k => {
      number     = v.number
      project_id = v.id
      project    = v
      automation = (
        lookup(local.projects[k], "automation", null) == null
        ? null
        : merge(
          local.projects[k].automation,
          {
            outputs_bucket = try(module.automation-bucket["${k}-outputs"].name, null)
            bucket         = try(module.automation-bucket[k].name, null)
            service_accounts = {
              for kk, vv in module.automation-service-accounts :
              replace(kk, "${k}/automation/", "") => vv.email
              if startswith(kk, "${k}/")
            }
          }
        )
      )
      service_agents = {
        for k, v in v.service_agents : k => v.email if v.is_primary
      }
    }
  }
}

output "service_accounts" {
  description = "Service account emails."
  value       = module.service-accounts
}

resource "google_storage_bucket_object" "workflows" {
  for_each = local.workflow_templates
  bucket   = each.value.outputs_bucket
  name     = "workflows/${each.key}.yaml"
  content = templatefile(
    "${var.template_search_path}/${each.value.template_path}",
    # This is the top-level map available in the template, with two keys.
    {
      # Namespace for all user-defined variables from the YAML `vars` block.
      vars = {
        for k, v in each.value.template_vars : k =>
        # If the value is a known CI/CD SA, substitute its email.
        can(local.projects[each.value.project_key].automation.cicd_config.impersonations[v]) ?
        module.automation-service-accounts["${each.value.project_key}/automation/${v}"].email
        # Otherwise, pass the value through as-is.
        : v
      },
      # Namespace for all module-provided ("global") variables.
      global = {
        workflow_name  = "Project ${each.value.project_key} - ${each.value.workflow_key}"
        outputs_bucket = each.value.outputs_bucket
        identity_provider = var.factories_config.context.federated_identity_providers[
          local.projects[each.value.project_key
        ].automation.cicd_config.identity_provider].name
        audiences = try(var.factories_config.context.federated_identity_providers[
          local.projects[each.value.project_key
        ].automation.cicd_config.identity_provider].audiences, null)
        # The map of provider files, impersonation, inside the 'global' namespace.
        provider_file = {
          for impersonator, role in local.projects[each.value.project_key].automation.cicd_config.impersonations :
          role => format(
            "%s-%s-provider.tf",
            each.value.project_key,
            role
          )
        }
      }
    }
  )
}

resource "local_file" "workflows" {
  for_each        = var.automation_outputs.local_path == null ? {} : local.workflow_templates
  file_permission = "0644"
  filename = "${
    pathexpand(var.automation_outputs.local_path)
  }/workflows/${var.automation_outputs.stage_name}/${each.key}.yaml"
  content = resource.google_storage_bucket_object.workflows[each.key].content
}

resource "google_storage_bucket_object" "providers" {
  for_each = {
    for v in flatten([
      for key, p in local.cicd_projects :
      [
        for impersonator_sa, impersonated_sa in try(p.automation.cicd_config.impersonations, {}) :
        {
          provider_template = try(p.automation.templates.provider, "providers.tf.tpl"),
          file_key          = "${key}-${impersonated_sa}-provider",
          project_key       = key,
          bucket            = module.automation-bucket[key].name,
          outputs_bucket    = local.project_outputs_bucket_names[key],
          project_id        = p.automation.project,
          project_number    = local._project_numbers[p.automation.project],
          service_account   = module.automation-service-accounts["${key}/automation/${impersonated_sa}"].email
        }
      ]
    ]) : v.file_key => v
  }
  bucket = each.value.outputs_bucket
  name   = "providers/${each.key}.tf"
  content = templatefile(
    "${var.template_search_path}/${each.value.provider_template}",
    {
      bucket          = each.value.bucket,
      outputs_bucket  = each.value.outputs_bucket,
      project_id      = each.value.project_id,
      project_number  = each.value.project_number,
      service_account = each.value.service_account
    }
  )
}

resource "local_file" "providers" {
  for_each = var.automation_outputs.local_path == null ? {} : resource.google_storage_bucket_object.providers
  content  = each.value.content
  filename = "${
    pathexpand(var.automation_outputs.local_path)
  }/providers/${var.automation_outputs.stage_name}/${each.key}.tf"
}