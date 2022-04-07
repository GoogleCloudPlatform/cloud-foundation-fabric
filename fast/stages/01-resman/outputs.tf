/**
 * Copyright 2022 Google LLC
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
  folder_ids = merge(
    {
      data-platform   = module.branch-dp-dev-folder.id
      networking      = module.branch-network-folder.id
      networking-dev  = module.branch-network-dev-folder.id
      networking-prod = module.branch-network-prod-folder.id
      sandbox         = module.branch-sandbox-folder.id
      security        = module.branch-security-folder.id
      teams           = module.branch-teams-folder.id
    },
    {
      for k, v in module.branch-teams-team-folder : "team-${k}" => v.id
    },
    {
      for k, v in module.branch-teams-team-dev-folder : "team-${k}-dev" => v.id
    },
    {
      for k, v in module.branch-teams-team-prod-folder : "team-${k}-prod" => v.id
    }
  )
  outputs_location = (
    var.outputs_location != null && var.outputs_location != ""
  )
  providers = {
    "02-networking" = templatefile("${path.module}/providers.tpl", {
      bucket = module.branch-network-gcs.name
      name   = "networking"
      sa     = module.branch-network-sa.email
    })
    "02-security" = templatefile("${path.module}/providers.tpl", {
      bucket = module.branch-security-gcs.name
      name   = "security"
      sa     = module.branch-security-sa.email
    })
    "03-data-platform-dev" = templatefile("${path.module}/providers.tpl", {
      bucket = module.branch-dp-dev-gcs.name
      name   = "dp-dev"
      sa     = module.branch-dp-dev-sa.email
    })
    "03-data-platform-prod" = templatefile("${path.module}/providers.tpl", {
      bucket = module.branch-dp-prod-gcs.name
      name   = "dp-prod"
      sa     = module.branch-dp-prod-sa.email
    })
    "03-project-factory-dev" = templatefile("${path.module}/providers.tpl", {
      bucket = module.branch-teams-dev-pf-gcs.name
      name   = "team-dev"
      sa     = module.branch-teams-dev-pf-sa.email
    })
    "03-project-factory-prod" = templatefile("${path.module}/providers.tpl", {
      bucket = module.branch-teams-prod-pf-gcs.name
      name   = "team-prod"
      sa     = module.branch-teams-prod-pf-sa.email
    })
    "99-sandbox" = templatefile("${path.module}/providers.tpl", {
      bucket = module.branch-sandbox-gcs.name
      name   = "sandbox"
      sa     = module.branch-sandbox-sa.email
    })
  }
  service_accounts = merge(
    {
      data-platform-dev    = module.branch-dp-dev-sa.email
      data-platform-prod   = module.branch-dp-prod-sa.email
      networking           = module.branch-network-sa.email
      project-factory-dev  = module.branch-teams-dev-pf-sa.email
      project-factory-prod = module.branch-teams-prod-pf-sa.email
      sandbox              = module.branch-sandbox-sa.email
      security             = module.branch-security-sa.email
      teams                = module.branch-teams-prod-sa.email
    },
    {
      for k, v in module.branch-teams-team-sa : "team-${k}" => v.email
    },
  )
  tfvars = {
    folder_ids       = local.folder_ids
    service_accounts = local.service_accounts
  }
}

# optionally generate providers and tfvars files for subsequent stages

resource "local_file" "providers" {
  for_each        = local.outputs_location ? {} : local.providers
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/providers/${each.key}-providers.tf"
  content         = each.value
}

resource "local_file" "tfvars" {
  for_each        = local.outputs_location ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/tfvars/01-resman.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

# outputs

output "dataplatform" {
  description = "Data for the Data Platform stage."
  value = {
    dev = {
      folder          = module.branch-dp-dev-folder.id
      gcs_bucket      = module.branch-dp-dev-gcs.name
      service_account = module.branch-dp-dev-sa.email
    }
    prod = {
      folder          = module.branch-dp-prod-folder.id
      gcs_bucket      = module.branch-dp-prod-gcs.name
      service_account = module.branch-dp-prod-sa.email
    }
  }
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
  value = {
    dev = {
      bucket = module.branch-teams-dev-pf-gcs.name
      sa     = module.branch-teams-dev-pf-sa.email
    }
    prod = {
      bucket = module.branch-teams-prod-pf-gcs.name
      sa     = module.branch-teams-prod-pf-sa.email
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
  value = {
    folder          = module.branch-sandbox-folder.id
    gcs_bucket      = module.branch-sandbox-gcs.name
    service_account = module.branch-sandbox-sa.email
  }
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
