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
  _tpl_providers = "${path.module}/templates/providers.tf.tpl"
  cicd_workflow_attrs = {
    data_platform_dev = {
      service_account   = try(module.branch-dp-dev-sa-cicd[0].email, null)
      tf_providers_file = "3-data-platform-dev-providers.tf"
      tf_var_files      = local.cicd_workflow_var_files.stage_3
    }
    data_platform_prod = {
      service_account   = try(module.branch-dp-prod-sa-cicd[0].email, null)
      tf_providers_file = "3-data-platform-prod-providers.tf"
      tf_var_files      = local.cicd_workflow_var_files.stage_3
    }
    gke_dev = {
      service_account   = try(module.branch-gke-dev-sa-cicd[0].email, null)
      tf_providers_file = "3-gke-dev-providers.tf"
      tf_var_files      = local.cicd_workflow_var_files.stage_3
    }
    gke_prod = {
      service_account   = try(module.branch-gke-prod-sa-cicd[0].email, null)
      tf_providers_file = "3-gke-prod-providers.tf"
      tf_var_files      = local.cicd_workflow_var_files.stage_3
    }
    networking = {
      service_account   = try(module.branch-network-sa-cicd[0].email, null)
      tf_providers_file = "2-networking-providers.tf"
      tf_var_files      = local.cicd_workflow_var_files.stage_2
    }
    project_factory_dev = {
      service_account   = try(module.branch-pf-dev-sa-cicd[0].email, null)
      tf_providers_file = "3-project-factory-dev-providers.tf"
      tf_var_files      = local.cicd_workflow_var_files.stage_3
    }
    project_factory_prod = {
      service_account   = try(module.branch-pf-prod-sa-cicd[0].email, null)
      tf_providers_file = "3-project-factory-prod-providers.tf"
      tf_var_files      = local.cicd_workflow_var_files.stage_3
    }
    security = {
      service_account   = try(module.branch-security-sa-cicd[0].email, null)
      tf_providers_file = "2-security-providers.tf"
      tf_var_files      = local.cicd_workflow_var_files.stage_2
    }
  }
  cicd_workflows = {
    for k, v in local.cicd_repositories : k => templatefile(
      "${path.module}/templates/workflow-${v.type}.yaml",
      merge(local.cicd_workflow_attrs[k], {
        audiences = try(
          local.cicd_identity_providers[v.identity_provider].audiences, null
        )
        identity_provider = try(
          local.cicd_identity_providers[v.identity_provider].name, null
        )
        outputs_bucket = var.automation.outputs_bucket
        stage_name     = k
      })
    )
  }
  folder_ids = merge(
    {
      data-platform-dev  = try(module.branch-dp-dev-folder[0].id, null)
      data-platform-prod = try(module.branch-dp-prod-folder[0].id, null)
      gke-dev            = try(module.branch-gke-dev-folder[0].id, null)
      gke-prod           = try(module.branch-gke-prod-folder[0].id, null)
      networking         = module.branch-network-folder.id
      networking-dev     = module.branch-network-dev-folder.id
      networking-prod    = module.branch-network-prod-folder.id
      sandbox            = try(module.branch-sandbox-folder[0].id, null)
      security           = module.branch-security-folder.id
      teams              = try(module.branch-teams-folder[0].id, null)
    },
    {
      for k, v in module.branch-teams-team-folder :
      "team-${k}" => v.id
    },
    {
      for k, v in module.branch-teams-team-dev-folder :
      "team-${k}-dev" => v.id
    },
    {
      for k, v in module.branch-teams-team-prod-folder :
      "team-${k}-prod" => v.id
    }
  )
  providers = merge(
    {
      "2-networking" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-network-gcs.name
        name          = "networking"
        sa            = module.branch-network-sa.email
      })
      "2-security" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-security-gcs.name
        name          = "security"
        sa            = module.branch-security-sa.email
      })
    },
    !var.fast_features.data_platform ? {} : {
      "3-data-platform-dev" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-dp-dev-gcs[0].name
        name          = "dp-dev"
        sa            = module.branch-dp-dev-sa[0].email
      })
      "3-data-platform-prod" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-dp-prod-gcs[0].name
        name          = "dp-prod"
        sa            = module.branch-dp-prod-sa[0].email
      })
    },
    !var.fast_features.gke ? {} : {
      "3-gke-dev" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-gke-dev-gcs[0].name
        name          = "gke-dev"
        sa            = module.branch-gke-dev-sa[0].email
      })
      "3-gke-prod" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-gke-prod-gcs[0].name
        name          = "gke-prod"
        sa            = module.branch-gke-prod-sa[0].email
      })
    },
    !var.fast_features.project_factory ? {} : {
      "3-project-factory-dev" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-pf-dev-gcs[0].name
        name          = "team-dev"
        sa            = var.automation.service_accounts.pf-dev
      })
      "3-project-factory-prod" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-pf-prod-gcs[0].name
        name          = "team-prod"
        sa            = var.automation.service_accounts.pf-prod
      })
    },
    !var.fast_features.sandbox ? {} : {
      "9-sandbox" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-sandbox-gcs[0].name
        name          = "sandbox"
        sa            = var.automation.service_accounts.sandbox
      })
    },
    !var.fast_features.teams ? {} : merge(
      {
        "3-teams" = templatefile(local._tpl_providers, {
          backend_extra = null
          bucket        = module.branch-teams-gcs[0].name
          name          = "teams"
          sa            = module.branch-teams-sa[0].email
        })
      },
      {
        for k, v in module.branch-teams-team-sa :
        "3-teams-${k}" => templatefile(local._tpl_providers, {
          backend_extra = null
          bucket        = module.branch-teams-team-gcs[k].name
          name          = "teams"
          sa            = v.email
        })
      }
    )
  )
  tfvars = {
    folder_ids = local.folder_ids
  }
}

output "cicd_repositories" {
  description = "WIF configuration for CI/CD repositories."
  value = {
    for k, v in local.cicd_repositories : k => {
      branch = v.branch
      name   = v.name
      provider = try(
        local.cicd_identity_providers[v.identity_provider].name, null
      )
      service_account = local.cicd_workflow_attrs[k].service_account
    } if v != null
  }
}

output "dataplatform" {
  description = "Data for the Data Platform stage."
  value = !var.fast_features.data_platform ? {} : {
    dev = {
      folder          = module.branch-dp-dev-folder[0].id
      gcs_bucket      = module.branch-dp-dev-gcs[0].name
      service_account = module.branch-dp-dev-sa[0].email
    }
    prod = {
      folder          = module.branch-dp-prod-folder[0].id
      gcs_bucket      = module.branch-dp-prod-gcs[0].name
      service_account = module.branch-dp-prod-sa[0].email
    }
  }
}

output "gke_multitenant" {
  # tfdoc:output:consumers 03-gke-multitenant
  description = "Data for the GKE multitenant stage."
  value = (
    var.fast_features.gke
    ? {
      "dev" = {
        folder          = module.branch-gke-dev-folder[0].id
        gcs_bucket      = module.branch-gke-dev-gcs[0].name
        service_account = module.branch-gke-dev-sa[0].email
      }
      "prod" = {
        folder          = module.branch-gke-prod-folder[0].id
        gcs_bucket      = module.branch-gke-prod-gcs[0].name
        service_account = module.branch-gke-prod-sa[0].email
      }
    }
    : {}
  )
}

output "networking" {
  description = "Data for the networking stage."
  value = {
    folder          = module.branch-network-folder.id
    gcs_bucket      = module.branch-network-gcs.name
    service_account = module.branch-network-sa.iam_email
  }
}

output "project_factories" {
  description = "Data for the project factories stage."
  value = !var.fast_features.project_factory ? {} : {
    dev = {
      bucket = module.branch-pf-dev-gcs[0].name
      sa     = var.automation.service_accounts.pf-dev
    }
    prod = {
      bucket = module.branch-pf-prod-gcs[0].name
      sa     = var.automation.service_accounts.pf-prod
    }
  }
}

# ready to use provider configurations for subsequent stages
output "providers" {
  # tfdoc:output:consumers 02-networking 02-security 03-dataplatform xx-sandbox xx-teams
  description = "Terraform provider files for this stage and dependent stages."
  sensitive   = true
  value       = local.providers
}

output "sandbox" {
  # tfdoc:output:consumers xx-sandbox
  description = "Data for the sandbox stage."
  value = (
    var.fast_features.sandbox
    ? {
      folder          = module.branch-sandbox-folder[0].id
      gcs_bucket      = module.branch-sandbox-gcs[0].name
      service_account = var.automation.service_accounts.sandbox
    }
    : null
  )
}

output "security" {
  # tfdoc:output:consumers 02-security
  description = "Data for the networking stage."
  value = {
    folder          = module.branch-security-folder.id
    gcs_bucket      = module.branch-security-gcs.name
    service_account = module.branch-security-sa.iam_email
  }
}

output "teams" {
  description = "Data for the teams stage."
  value = {
    for k, v in module.branch-teams-team-folder : k => {
      folder          = v.id
      gcs_bucket      = module.branch-teams-team-gcs[k].name
      service_account = module.branch-teams-team-sa[k].email
    }
  }
}

# ready to use variable values for subsequent stages
output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}
