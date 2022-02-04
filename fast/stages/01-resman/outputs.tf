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
  _project_factory_sas = {
    dev  = module.branch-teams-dev-projectfactory-sa.iam_email
    prod = module.branch-teams-prod-projectfactory-sa.iam_email
  }
  _gke_multitenant_sas = {
    dev  = module.branch-gke-multitenant-dev-sa.iam_email
    prod = module.branch-gke-multitenant-prod-sa.iam_email
  }
  providers = {
    "02-networking" = templatefile("${path.module}/../../assets/templates/providers.tpl", {
      bucket = module.branch-network-gcs.name
      name   = "networking"
      sa     = module.branch-network-sa.email
    })
    "02-networking-nva" = templatefile("${path.module}/../../assets/templates/providers.tpl", {
      bucket = module.branch-network-gcs.name
      name   = "networking-nva"
      sa     = module.branch-network-sa.email
    })
    "02-security" = templatefile("${path.module}/../../assets/templates/providers.tpl", {
      bucket = module.branch-security-gcs.name
      name   = "security"
      sa     = module.branch-security-sa.email
    })
    "03-gke-multitenant-dev" = templatefile("${path.module}/../../assets/templates/providers.tpl", {
      bucket = module.branch-gke-multitenant-dev-gcs.name
      name   = "gke-multitenant-dev"
      sa     = module.branch-gke-multitenant-dev-sa.email
    })
    "03-gke-multitenant-prod" = templatefile("${path.module}/../../assets/templates/providers.tpl", {
      bucket = module.branch-gke-multitenant-prod-gcs.name
      name   = "gke-multitenant-prod"
      sa     = module.branch-gke-multitenant-prod-sa.email
    })
    "03-project-factory-dev" = templatefile("${path.module}/../../assets/templates/providers.tpl", {
      bucket = module.branch-teams-dev-projectfactory-gcs.name
      name   = "team-dev"
      sa     = module.branch-teams-dev-projectfactory-sa.email
    })
    "03-project-factory-prod" = templatefile("${path.module}/../../assets/templates/providers.tpl", {
      bucket = module.branch-teams-prod-projectfactory-gcs.name
      name   = "team-prod"
      sa     = module.branch-teams-prod-projectfactory-sa.email
    })
    "99-sandbox" = templatefile("${path.module}/../../assets/templates/providers.tpl", {
      bucket = module.branch-sandbox-gcs.name
      name   = "sandbox"
      sa     = module.branch-sandbox-sa.email
    })
  }
  tfvars = {
    "02-networking" = jsonencode({
      folder_ids = {
        networking      = module.branch-network-folder.id
        networking-dev  = module.branch-network-dev-folder.id
        networking-prod = module.branch-network-prod-folder.id
      }
      project_factory_sa = local._project_factory_sas
      gke_multitenant_sa = local._gke_multitenant_sas
    })
    "02-security" = jsonencode({
      folder_id = module.branch-security-folder.id
      kms_restricted_admins = {
        for k, v in local._project_factory_sas : k => [v]
      }
    })
    "03-gke-multitenant-dev" = jsonencode({
      folder_id   = module.branch-gke-multitenant-dev-folder.id
      environment = "dev"
    })
    "03-gke-multitenant-prod" = jsonencode({
      folder_id   = module.branch-gke-multitenant-prod-folder.id
      environment = "prod"
    })
  }
}

# optionally generate providers and tfvars files for subsequent stages

resource "local_file" "providers" {
  for_each = var.outputs_location == null ? {} : local.providers
  filename = "${var.outputs_location}/${each.key}/providers.tf"
  content  = each.value
}

resource "local_file" "tfvars" {
  for_each = var.outputs_location == null ? {} : local.tfvars
  filename = "${var.outputs_location}/${each.key}/terraform-resman.auto.tfvars.json"
  content  = each.value
}

# outputs

output "networking" {
  # tfdoc:output:consumers 02-networking
  description = "Data for the networking stage."
  value = {
    folder          = module.branch-network-folder.id
    gcs_bucket      = module.branch-network-gcs.name
    service_account = module.branch-network-sa.iam_email
  }
}

output "project_factories" {
  # tfdoc:output:consumers xx-teams
  description = "Data for the project factories stage."
  value = {
    dev = {
      bucket = module.branch-teams-dev-projectfactory-gcs.name
      sa     = module.branch-teams-dev-projectfactory-sa.email
    }
    prod = {
      bucket = module.branch-teams-prod-projectfactory-gcs.name
      sa     = module.branch-teams-prod-projectfactory-sa.email
    }
  }
}

# ready to use provider configurations for subsequent stages

output "providers" {
  # tfdoc:output:consumers 02-networking 02-security xx-sandbox xx-teams
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

output "gke_multitenant" {
  # tfdoc:output:consumers 03-gke-multitenant
  description = "Data for the GKE multitenant stage."
  value = {
    "dev" = {
      folder          = module.branch-gke-multitenant-dev-folder.id
      gcs_bucket      = module.branch-gke-multitenant-dev-gcs.name
      service_account = module.branch-gke-multitenant-dev-sa.email
    }
    "prod" = {
      folder          = module.branch-gke-multitenant-prod-folder.id
      gcs_bucket      = module.branch-gke-multitenant-prod-gcs.name
      service_account = module.branch-gke-multitenant-prod-sa.email
    }
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
