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
  _tpl_providers = "${path.module}/templates/providers.tf.tpl"
  cicd_workflow_attrs = {
    data_platform_dev = {
      service_accounts = {
        apply = try(module.branch-dp-dev-sa-cicd[0].email, null)
        plan  = try(module.branch-dp-dev-r-sa-cicd[0].email, null)
      }
      tf_providers_files = {
        apply = "3-data-platform-dev-providers.tf"
        plan  = "3-data-platform-dev-r-providers.tf"
      }
      tf_var_files = local.cicd_workflow_var_files.stage_3
    }
    data_platform_prod = {
      service_accounts = {
        apply = try(module.branch-dp-prod-sa-cicd[0].email, null)
        plan  = try(module.branch-dp-prod-r-sa-cicd[0].email, null)
      }
      tf_providers_files = {
        apply = "3-data-platform-prod-providers.tf"
        plan  = "3-data-platform-prod-r-providers.tf"
      }
      tf_var_files = local.cicd_workflow_var_files.stage_3
    }
    gcve_dev = {
      service_accounts = {
        apply = try(module.branch-gcve-dev-sa-cicd[0].email, null)
        plan  = try(module.branch-gcve-dev-r-sa-cicd[0].email, null)
      }
      tf_providers_files = {
        apply = "3-gcve-dev-providers.tf"
        plan  = "3-gcve-dev-r-providers.tf"
      }
      tf_var_files = local.cicd_workflow_var_files.stage_3
    }
    gcve_prod = {
      service_accounts = {
        apply = try(module.branch-gcve-prod-sa-cicd[0].email, null)
        plan  = try(module.branch-gcve-prod-r-sa-cicd[0].email, null)
      }
      tf_providers_files = {
        apply = "3-gcve-prod-providers.tf"
        plan  = "3-gcve-prod-r-providers.tf"
      }
      tf_var_files = local.cicd_workflow_var_files.stage_3
    }
    gke_dev = {
      service_accounts = {
        apply = try(module.branch-gke-dev-sa-cicd[0].email, null)
        plan  = try(module.branch-gke-dev-r-sa-cicd[0].email, null)
      }
      tf_providers_files = {
        apply = "3-gke-dev-providers.tf"
        plan  = "3-gke-dev-r-providers.tf"
      }
      tf_var_files = local.cicd_workflow_var_files.stage_3
    }
    gke_prod = {
      service_accounts = {
        apply = try(module.branch-gke-prod-sa-cicd[0].email, null)
        plan  = try(module.branch-gke-prod-r-sa-cicd[0].email, null)
      }
      tf_providers_files = {
        apply = "3-gke-prod-providers.tf"
        plan  = "3-gke-prod-r-providers.tf"
      }
      tf_var_files = local.cicd_workflow_var_files.stage_3
    }
    networking = {
      service_accounts = {
        apply = try(module.branch-network-sa-cicd[0].email, null)
        plan  = try(module.branch-network-r-sa-cicd[0].email, null)
      }
      tf_providers_files = {
        apply = "2-networking-providers.tf"
        plan  = "2-networking-r-providers.tf"
      }
      tf_var_files = local.cicd_workflow_var_files.stage_2
    }
    project_factory_dev = {
      service_accounts = {
        apply = try(module.branch-pf-dev-sa-cicd[0].email, null)
        plan  = try(module.branch-pf-dev-r-sa-cicd[0].email, null)
      }
      tf_providers_files = {
        apply = "3-project-factory-dev-providers.tf"
        plan  = "3-project-factory-dev-r-providers.tf"
      }
      tf_var_files = local.cicd_workflow_var_files.stage_3
    }
    project_factory_prod = {
      service_accounts = {
        apply = try(module.branch-pf-prod-sa-cicd[0].email, null)
        plan  = try(module.branch-pf-prod-r-sa-cicd[0].email, null)
      }
      tf_providers_files = {
        apply = "3-project-factory-prod-providers.tf"
        plan  = "3-project-factory-prod-r-providers.tf"
      }
      tf_var_files = local.cicd_workflow_var_files.stage_3
    }
    security = {
      service_accounts = {
        apply = try(module.branch-security-sa-cicd[0].email, null)
        plan  = try(module.branch-security-r-sa-cicd[0].email, null)
      }
      tf_providers_files = {
        apply = "2-security-providers.tf"
        plan  = "2-security-r-providers.tf"
      }
      tf_var_files = local.cicd_workflow_var_files.stage_2
    }
  }
  cicd_workflows = {
    for k, v in local.cicd_repositories : k => templatefile(
      "${path.module}/templates/workflow-${v.type}.yaml",
      merge(local.cicd_workflow_attrs[k], {
        audiences = try(
          local.identity_providers[v.identity_provider].audiences, null
        )
        identity_provider = try(
          local.identity_providers[v.identity_provider].name, null
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
      gcve-dev           = try(module.branch-gcve-dev-folder[0].id, null)
      gcve-prod          = try(module.branch-gcve-prod-folder[0].id, null)
      gke-dev            = try(module.branch-gke-dev-folder[0].id, null)
      gke-prod           = try(module.branch-gke-prod-folder[0].id, null)
      networking         = try(module.branch-network-folder.id, null)
      networking-dev     = try(module.branch-network-dev-folder.id, null)
      networking-prod    = try(module.branch-network-prod-folder.id, null)
      sandbox            = try(module.branch-sandbox-folder[0].id, null)
      security           = try(module.branch-security-folder.id, null)
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
      "2-networking-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-network-gcs.name
        name          = "networking"
        sa            = module.branch-network-r-sa.email
      })
      "2-security" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-security-gcs.name
        name          = "security"
        sa            = module.branch-security-sa.email
      })
      "2-security-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-security-gcs.name
        name          = "security"
        sa            = module.branch-security-r-sa.email
      })
    },
    !var.fast_features.data_platform ? {} : {
      "3-data-platform-dev" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-dp-dev-gcs[0].name
        name          = "dp-dev"
        sa            = module.branch-dp-dev-sa[0].email
      })
      "3-data-platform-dev-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-dp-dev-gcs[0].name
        name          = "dp-dev"
        sa            = module.branch-dp-dev-r-sa[0].email
      })
      "3-data-platform-prod" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-dp-prod-gcs[0].name
        name          = "dp-prod"
        sa            = module.branch-dp-prod-sa[0].email
      })
      "3-data-platform-prod-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-dp-prod-gcs[0].name
        name          = "dp-prod"
        sa            = module.branch-dp-prod-r-sa[0].email
      })
    },
    !var.fast_features.gke ? {} : {
      "3-gke-dev" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-gke-dev-gcs[0].name
        name          = "gke-dev"
        sa            = module.branch-gke-dev-sa[0].email
      })
      "3-gke-dev-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-gke-dev-gcs[0].name
        name          = "gke-dev"
        sa            = module.branch-gke-dev-r-sa[0].email
      })
      "3-gke-prod" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-gke-prod-gcs[0].name
        name          = "gke-prod"
        sa            = module.branch-gke-prod-sa[0].email
      })
      "3-gke-prod-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-gke-prod-gcs[0].name
        name          = "gke-prod"
        sa            = module.branch-gke-prod-r-sa[0].email
      })
    },
    !var.fast_features.gcve ? {} : {
      "3-gcve-dev" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-gcve-dev-gcs[0].name
        name          = "gcve-dev"
        sa            = module.branch-gcve-dev-sa[0].email
      })
      "3-gcve-dev-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-gcve-dev-gcs[0].name
        name          = "gcve-dev"
        sa            = module.branch-gcve-dev-r-sa[0].email
      })
      "3-gcve-prod" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-gcve-prod-gcs[0].name
        name          = "gcve-prod"
        sa            = module.branch-gcve-prod-sa[0].email
      })
      "3-gcve-prod-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-gcve-prod-gcs[0].name
        name          = "gcve-prod"
        sa            = module.branch-gcve-prod-r-sa[0].email
      })
    },
    !var.fast_features.project_factory ? {} : {
      "3-project-factory-dev" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-pf-dev-gcs[0].name
        name          = "team-dev"
        sa            = module.branch-pf-dev-sa[0].email
      })
      "3-project-factory-dev-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-pf-dev-gcs[0].name
        name          = "team-dev"
        sa            = module.branch-pf-dev-r-sa[0].email
      })
      "3-project-factory-prod" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-pf-prod-gcs[0].name
        name          = "team-prod"
        sa            = module.branch-pf-prod-sa[0].email
      })
      "3-project-factory-prod-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-pf-prod-gcs[0].name
        name          = "team-prod"
        sa            = module.branch-pf-prod-r-sa[0].email
      })
    },
    !var.fast_features.sandbox ? {} : {
      "9-sandbox" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-sandbox-gcs[0].name
        name          = "sandbox"
        sa            = module.branch-sandbox-sa[0].email
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
  service_accounts = merge(
    {
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
      networking             = module.branch-network-sa.email
      networking-r           = module.branch-network-r-sa.email
      project-factory-dev    = try(module.branch-pf-dev-sa[0].email, null)
      project-factory-dev-r  = try(module.branch-pf-dev-r-sa[0].email, null)
      project-factory-prod   = try(module.branch-pf-prod-sa[0].email, null)
      project-factory-prod-r = try(module.branch-pf-prod-r-sa[0].email, null)
      sandbox                = try(module.branch-sandbox-sa[0].email, null)
      security               = module.branch-security-sa.email
      security-r             = module.branch-security-r-sa.email
      teams                  = try(module.branch-teams-sa[0].email, null)
    },
    {
      for k, v in module.branch-teams-team-sa : "team-${k}" => v.email
    },
  )
  team_cicd_workflows = {
    for k, v in local.team_cicd_repositories : k => templatefile(
      "${path.module}/templates/workflow-${v.cicd.type}.yaml",
      merge(local.team_cicd_workflow_attrs[k], {
        identity_provider = try(
          local.identity_providers[v.cicd.identity_provider].name, null
        )
        outputs_bucket = var.automation.outputs_bucket
        stage_name     = k
      })
    )
  }
  team_cicd_workflow_attrs = {
    for k, v in local.team_cicd_repositories : k => {
      service_account   = try(module.branch-teams-team-sa-cicd[k].email, null)
      tf_providers_file = "3-teams-${k}-providers.tf"
      tf_var_files      = local.cicd_workflow_var_files.stage_3
    }
  }
  tfvars = {
    checklist_hierarchy = local.checklist.hierarchy
    folder_ids          = local.folder_ids
    service_accounts    = local.service_accounts
    tag_keys            = { for k, v in try(module.organization.tag_keys, {}) : k => v.id }
    tag_names           = var.tag_names
    tag_values          = { for k, v in try(module.organization.tag_values, {}) : k => v.id }
  }
}

output "cicd_repositories" {
  description = "WIF configuration for CI/CD repositories."
  value = {
    for k, v in local.cicd_repositories : k => {
      branch = v.branch
      name   = v.name
      provider = try(
        local.identity_providers[v.identity_provider].name, null
      )
      service_account = local.cicd_workflow_attrs[k].service_accounts
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

output "gcve" {
  # tfdoc:output:consumers 03-gke-multitenant
  description = "Data for the GCVE stage."
  value = (
    var.fast_features.gcve
    ? {
      "dev" = {
        folder          = module.branch-gcve-dev-folder[0].id
        gcs_bucket      = module.branch-gcve-dev-gcs[0].name
        service_account = module.branch-gcve-dev-sa[0].email
      }
      "prod" = {
        folder          = module.branch-gcve-prod-folder[0].id
        gcs_bucket      = module.branch-gcve-prod-gcs[0].name
        service_account = module.branch-gcve-prod-sa[0].email
      }
    }
    : {}
  )
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
      sa     = module.branch-pf-dev-sa[0].email
    }
    prod = {
      bucket = module.branch-pf-prod-gcs[0].name
      sa     = module.branch-pf-prod-sa[0].email
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
      service_account = module.branch-sandbox-sa[0].email
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

output "team_cicd_repositories" {
  description = "WIF configuration for Team CI/CD repositories."
  value = {
    for k, v in local.team_cicd_repositories : k => {
      branch = v.cicd.branch
      name   = v.cicd.name
      provider = try(
        local.identity_providers[v.cicd.identity_provider].name, null
      )
      service_account = local.team_cicd_workflow_attrs[k].service_account
    } if v.cicd != null
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
