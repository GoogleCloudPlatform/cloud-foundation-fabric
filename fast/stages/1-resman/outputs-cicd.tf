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
  cicd_workflows = {
    for k, v in local._cicd_workflow_attrs : k => templatefile(
      "${path.module}/templates/workflow-${v.repository.type}.yaml", v
    )
  }
  _cicd_workflow_attrs = merge(
    # stage 2
    lookup(local.cicd_repositories, "networking", null) == null ? {} : tomap({
      service_accounts = {
        apply = module.net-sa-rw[0].email
        plan  = module.net-sa-ro[0].email
      }
      tf_providers_files = {
        apply = "2-networking-providers.tf"
        plan  = "2-networking-providers-r.tf"
      }
      tf_var_files = local.cicd_workflow_files.stage_2
      audiences = try(
        local.identity_providers[local.cicd_repositories.networking.identity_provider].audiences, null
      )
      identity_provider = try(
        local.identity_providers[local.cicd_repositories.networking.identity_provider].name, null
      )
      outputs_bucket = var.automation.outputs_bucket
      stage_name     = "networking"
    }),
    lookup(local.cicd_repositories, "security", null) == null ? {} : tomap({
      service_accounts = {
        apply = module.sec-sa-rw[0].email
        plan  = module.sec-sa-ro[0].email
      }
      tf_providers_files = {
        apply = "2-security-providers.tf"
        plan  = "2-security-providers-r.tf"
      }
      tf_var_files = local.cicd_workflow_files.stage_2
      audiences = try(
        local.identity_providers[local.cicd_repositories.security.identity_provider].audiences, null
      )
      identity_provider = try(
        local.identity_providers[local.cicd_repositories.security.identity_provider].name, null
      )
      outputs_bucket = var.automation.outputs_bucket
      stage_name     = "security"
    }),
    lookup(local.cicd_repositories, "project_factory", null) == null ? {} : tomap({
      service_accounts = {
        apply = module.pf-sa-rw[0].email
        plan  = module.pf-sa-ro[0].email
      }
      tf_providers_files = {
        apply = "2-project-factory-providers.tf"
        plan  = "2-project-factory-providers-r.tf"
      }
      tf_var_files = local.cicd_workflow_files.stage_2
      audiences = try(
        local.identity_providers[local.cicd_repositories.project_factory.identity_provider].audiences, null
      )
      identity_provider = try(
        local.identity_providers[local.cicd_repositories.project_factory.identity_provider].name, null
      )
      outputs_bucket = var.automation.outputs_bucket
      stage_name     = "project-factory"
    }),
    # stage 3
    {
      for k, v in local.cicd_repositories : "${v.lvl}-${k}" => {
        service_accounts = {
          apply = module.stage3-sa-prod-rw[0].email
          plan  = module.stage3-sa-prod-ro[0].email
        }
        tf_providers_files = {
          apply = "${v.lvl}-${k}-providers.tf"
          plan  = "${v.lvl}-${k}-providers-r.tf"
        }
        tf_var_files = local.cicd_workflow_files.stage_3
        audiences = try(
          local.identity_providers[v.identity_provider].audiences, null
        )
        identity_provider = try(
          local.identity_providers[v.identity_provider].name, null
        )
        outputs_bucket = var.automation.outputs_bucket
        stage_name     = v.short_name
      } if v.lvl == 3 && v.env == "prod"
    },
    {
      for k, v in local.cicd_repositories : "${v.lvl}-${k}" => {
        service_accounts = {
          apply = module.stage3-sa-dev-rw[0].email
          plan  = module.stage3-sa-dev-ro[0].email
        }
        tf_providers_files = {
          apply = "${v.lvl}-${k}-providers.tf"
          plan  = "${v.lvl}-${k}-providers-r.tf"
        }
        tf_var_files = local.cicd_workflow_files.stage_3
        audiences = try(
          local.identity_providers[v.identity_provider].audiences, null
        )
        identity_provider = try(
          local.identity_providers[v.identity_provider].name, null
        )
        outputs_bucket = var.automation.outputs_bucket
        stage_name     = v.short_name
      } if v.lvl == 3 && v.env == "dev"
    }
  )
}
