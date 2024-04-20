# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Folder resources.

locals {
  # Create Log sink ingress policies
  _sink_ingress_policies = var.enable_features.log_sink ? {
    log_sink = {
      from = {
        access_levels = ["*"]
        identities    = values(module.folder.sink_writer_identities)
      }
      to = {
        resources  = ["projects/${module.log-export-project[0].number}"]
        operations = [{ service_name = "*" }]
    } }
  } : null

  _vpc_sc_vpc_accessible_services = var.data_dir != null ? yamldecode(
    file("${var.data_dir}/vpc-sc/restricted-services.yaml")
  ) : null
  _vpc_sc_restricted_services = var.data_dir != null ? yamldecode(
    file("${var.data_dir}/vpc-sc/restricted-services.yaml")
  ) : null

  access_policy_create = var.access_policy_config.access_policy_create != null ? {
    parent = "organizations/${var.organization.id}"
    title  = "shielded-folder"
    scopes = [module.folder.id]
  } : null

  groups = {
    for k, v in var.groups : k => "${v}@${var.organization.domain}"
  }
  groups_iam = {
    for k, v in local.groups : k => "group:${v}"
  }
  iam_principals = {
    "group:${local.groups.workload-engineers}" = [
      "roles/editor",
      "roles/iam.serviceAccountTokenCreator"
    ]
  }

  vpc_sc_resources = [
    for k, v in data.google_projects.folder-projects.projects : format("projects/%s", v.number)
  ]

  log_sink_destinations = var.enable_features.log_sink ? merge(
    # use the same dataset for all sinks with `bigquery` as  destination
    { for k, v in var.log_sinks : k => module.log-export-dataset[0] if v.type == "bigquery" },
    # use the same gcs bucket for all sinks with `storage` as destination
    { for k, v in var.log_sinks : k => module.log-export-gcs[0] if v.type == "storage" },
    # use separate pubsub topics and logging buckets for sinks with
    # destination `pubsub` and `logging`
    module.log-export-pubsub,
    module.log-export-logbucket
  ) : null
}

module "folder" {
  source            = "../../../modules/folder"
  folder_create     = var.folder_config.folder_create != null
  parent            = try(var.folder_config.folder_create.parent, null)
  name              = try(var.folder_config.folder_create.display_name, null)
  id                = var.folder_config.folder_create != null ? null : var.folder_config.folder_id
  iam_by_principals = local.iam_principals
  factories_config = {
    org_policies = var.data_dir != null ? "${var.data_dir}/org-policies" : null
  }
  logging_sinks = var.enable_features.log_sink ? {
    for name, attrs in var.log_sinks : name => {
      bq_partitioned_table = attrs.type == "bigquery"
      destination          = local.log_sink_destinations[name].id
      filter               = attrs.filter
      type                 = attrs.type
    }
  } : null
}

module "firewall-policy" {
  source    = "../../../modules/net-firewall-policy"
  name      = "default"
  parent_id = module.folder.id
  factories_config = var.data_dir == null ? {} : {
    cidr_file_path          = "${var.data_dir}/firewall-policies/cidrs.yaml"
    ingress_rules_file_path = "${var.data_dir}/firewall-policies/hierarchical-ingress-rules.yaml"
  }
}

module "folder-workload" {
  source = "../../../modules/folder"
  parent = module.folder.id
  name   = "${var.prefix}-workload"
}

#TODO VPCSC: Access levels

data "google_projects" "folder-projects" {
  filter = "parent.id:${split("/", module.folder.id)[1]}"

  depends_on = [
    module.sec-project,
    module.log-export-project
  ]
}

module "vpc-sc" {
  count                = var.enable_features.vpc_sc ? 1 : 0
  source               = "../../../modules/vpc-sc"
  access_policy        = try(var.access_policy_config.policy_name, null)
  access_policy_create = local.access_policy_create
  access_levels        = var.vpc_sc_access_levels
  egress_policies      = var.vpc_sc_egress_policies
  ingress_policies     = merge(var.vpc_sc_ingress_policies, local._sink_ingress_policies)
  service_perimeters_regular = {
    shielded = {
      # Move `spec` definition to `status` and comment `use_explicit_dry_run_spec` variable to enforce VPC-SC configuration
      # Before enforcing configuration check logs and create Access Level, Ingress/Egress policy as needed

      status = null
      spec = {
        access_levels       = keys(var.vpc_sc_access_levels)
        resources           = local.vpc_sc_resources
        restricted_services = local._vpc_sc_restricted_services
        egress_policies     = keys(var.vpc_sc_egress_policies)
        ingress_policies    = keys(merge(var.vpc_sc_ingress_policies, local._sink_ingress_policies))
        vpc_accessible_services = {
          allowed_services   = local._vpc_sc_vpc_accessible_services
          enable_restriction = true
        }
      }
      use_explicit_dry_run_spec = true
    }
  }
}
