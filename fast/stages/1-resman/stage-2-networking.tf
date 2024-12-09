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
  # normalize IAM bindings for stage 3 service accounts
  net_s3_iam = !var.fast_stage_2.networking.enabled ? {} : {
    for v in local.stage3_iam_in_stage2 : "${v.role}:${v.env}" => (
      v.sa == "rw"
      ? module.stage3-sa-rw[v.s3].iam_email
      : module.stage3-sa-ro[v.s3].iam_email
    )...
    if v.s2 == "networking"
  }
  net_use_env_folders = (
    var.fast_stage_2.networking.enabled &&
    var.fast_stage_2.networking.folder_config.create_env_folders
  )
}

# top-level folder

module "net-folder" {
  source = "../../../modules/folder"
  count  = var.fast_stage_2.networking.enabled ? 1 : 0
  parent = (
    var.fast_stage_2.networking.folder_config.parent_id == null
    ? local.root_node
    : try(
      local.top_level_folder_ids[var.fast_stage_2.networking.folder_config.parent_id],
      var.fast_stage_2.networking.folder_config.parent_id
    )
  )
  name = var.fast_stage_2.networking.folder_config.name
  iam = merge(
    # stage own service accounts
    {
      "roles/logging.admin"                  = [module.net-sa-rw[0].iam_email]
      "roles/owner"                          = [module.net-sa-rw[0].iam_email]
      "roles/resourcemanager.folderAdmin"    = [module.net-sa-rw[0].iam_email]
      "roles/resourcemanager.projectCreator" = [module.net-sa-rw[0].iam_email]
      "roles/compute.xpnAdmin"               = [module.net-sa-rw[0].iam_email]
      "roles/resourcemanager.tagUser"        = [module.net-sa-rw[0].iam_email]
      "roles/viewer"                         = [module.net-sa-ro[0].iam_email]
      "roles/resourcemanager.folderViewer"   = [module.net-sa-ro[0].iam_email]
      "roles/resourcemanager.tagViewer"      = [module.net-sa-ro[0].iam_email]
    },
    # network security stage 2 service accounts
    var.fast_stage_2.network_security.enabled != true ? {} : {
      "roles/serviceusage.serviceUsageAdmin" = [
        module.nsec-sa-rw[0].iam_email
      ]
      (var.custom_roles["network_firewall_policies_admin"]) = [
        module.nsec-sa-rw[0].iam_email
      ]
      "roles/compute.orgFirewallPolicyUser" = [
        module.nsec-sa-ro[0].iam_email
      ]
      "roles/serviceusage.serviceUsageConsumer" = [
        module.nsec-sa-ro[0].iam_email
      ]
    },
    # security stage 2 service accounts
    var.fast_stage_2.security.enabled != true ? {} : {
      "roles/serviceusage.serviceUsageAdmin" = [
        module.sec-sa-rw[0].iam_email
      ]
      "roles/serviceusage.serviceUsageConsumer" = [
        module.sec-sa-ro[0].iam_email
      ]
    },
    # project factory service accounts
    (var.fast_stage_2.project_factory.enabled) != true ? {} : {
      (var.custom_roles.service_project_network_admin) = [
        module.pf-sa-rw[0].iam_email
      ]
      (var.custom_roles.project_iam_viewer) = [
        module.pf-sa-ro[0].iam_email
      ]
      "roles/compute.networkViewer" = [
        module.pf-sa-ro[0].iam_email
      ]
    }
  )
  iam_bindings = merge(
    # project factory delegated grant
    var.fast_stage_2.project_factory.enabled != true ? {} : {
      pf_delegated_grant = {
        role    = "roles/resourcemanager.projectIamAdmin"
        members = [module.pf-sa-rw[0].iam_email]
        condition = {
          expression = format(
            "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
            "'roles/compute.networkUser', 'roles/composer.sharedVpcAgent', 'roles/container.hostServiceAgentUser', 'roles/vpcaccess.user'"
          )
          title       = "project factory project delegated admin"
          description = "Project factory delegated grant."
        }
      }
    },
    # stage 3 roles
    {
      for k, v in local.net_s3_iam : k => {
        role    = lookup(var.custom_roles, split(":", k)[0], split(":", k)[0])
        members = v
        condition = {
          title      = "stage 3 ${split(":", k)[1]}"
          expression = <<-END
            resource.matchTag(
              '${local.tag_root}/${var.tag_names.environment}',
              '${split(":", k)[1]}'
            )
          END
        }
      }
    }
  )
  iam_by_principals = merge(
    {
      # replace with more selective custom roles for production deployments
      (local.principals.gcp-network-admins) = ["roles/editor"]
    },
    var.fast_stage_2.networking.folder_config.iam_by_principals
  )
  tag_bindings = {
    context = try(
      local.tag_values["${var.tag_names.context}/networking"].id, null
    )
  }
}

# optional per-environment folders

module "net-folder-prod" {
  source = "../../../modules/folder"
  count  = local.net_use_env_folders ? 1 : 0
  parent = module.net-folder[0].id
  name   = var.environments["prod"].name
  tag_bindings = {
    environment = try(
      local.tag_values["${var.tag_names.environment}/${var.environments["prod"].tag_name}"].id,
      null
    )
  }
}

module "net-folder-dev" {
  source = "../../../modules/folder"
  count  = local.net_use_env_folders ? 1 : 0
  parent = module.net-folder[0].id
  name   = var.environments["dev"].name
  tag_bindings = {
    environment = try(
      local.tag_values["${var.tag_names.environment}/${var.environments["dev"].tag_name}"].id,
      null
    )
  }
}

# automation service accounts

module "net-sa-rw" {
  source                 = "../../../modules/iam-service-account"
  count                  = var.fast_stage_2.networking.enabled ? 1 : 0
  project_id             = var.automation.project_id
  name                   = "prod-resman-${var.fast_stage_2.networking.short_name}-0"
  display_name           = "Terraform resman networking service account."
  prefix                 = var.prefix
  service_account_create = var.root_node == null
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-rw["networking"].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "net-sa-ro" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_stage_2.networking.enabled ? 1 : 0
  project_id   = var.automation.project_id
  name         = "prod-resman-${var.fast_stage_2.networking.short_name}-0r"
  display_name = "Terraform resman networking service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-ro["networking"].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = [var.custom_roles["storage_viewer"]]
  }
}

# automation bucket

module "net-bucket" {
  source     = "../../../modules/gcs"
  count      = var.fast_stage_2.networking.enabled ? 1 : 0
  project_id = var.automation.project_id
  name       = "prod-resman-${var.fast_stage_2.networking.short_name}-0"
  prefix     = var.prefix
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.net-sa-rw[0].iam_email]
    "roles/storage.objectViewer" = [module.net-sa-ro[0].iam_email]
  }
}
