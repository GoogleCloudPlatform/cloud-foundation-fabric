/**
 * Copyright 2021 Google LLC
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

##
## GITLAB FUNCTIONALITIES
##
## If you are not using Gitlab project/runner provisioning, please remove everything 
## below this line.

/*

data "google_client_config" "provider" {
}

locals {
  gitlab_gke_enabled = lookup(var.config, "gitlab", {}) != {} && var.config.gitlab.gke.project != "" ? true : false
}

data "google_container_cluster" "cluster" {
  count = local.gitlab_gke_enabled ? 1 : 0

  project  = var.config.gitlab.gke.project
  name     = var.config.gitlab.gke.cluster
  location = var.config.gitlab.gke.location
}

provider "template" {
}

provider "kubernetes" {
  host  = local.gitlab_gke_enabled ? format("https://%s", data.google_container_cluster.cluster[0].endpoint) : null
  token = data.google_client_config.provider.access_token 
  cluster_ca_certificate = local.gitlab_gke_enabled ? base64decode(
    lookup(data.google_container_cluster.cluster[0].master_auth[0], "cluster_ca_certificate", ""),
  ) : ""
}

provider "helm" {
  kubernetes {
    host  = local.gitlab_gke_enabled ? format("https://%s", data.google_container_cluster.cluster[0].endpoint) : ""
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = local.gitlab_gke_enabled ? base64decode(
        lookup(data.google_container_cluster.cluster[0].master_auth[0], "cluster_ca_certificate", ""),
    ) : ""
  }
}

provider "gitlab" {
  base_url = var.config.gitlab.url != "" ? var.config.gitlab.url
  token = var.config.gitlab.url != "" ? var.gitlab_admin_token : ""
}

module "gitlab" {
  for_each = lookup(lookup(var.config, "gitlab", {}), "url", "") != "" ? local.gitlab_projects : tomap({})

  source = "./modules/gitlab"
  providers = {
    helm = helm
    kubernetes = kubernetes
    template = template
    gitlab = gitlab
  }

  environments = each.value.environments
  project_id       = each.value.projectId
  project_ids_full = module.project[each.value.projectId].project_ids

  gitlab_project_id = each.value.gitlab.project
  gitlab_project_group = each.value.gitlab.group
  gitlab_project_runner = lookup(each.value.gitlab, "runner", false)
  gitlab_team = lookup(each.value, "team", {})
  gitlab_team_permissions = var.config.projectGroups
  gitlab_owners = [lookup(each.value, "owners", "")]
  
  gitlab_gke_project = var.config.gitlab.gke.project
  gitlab_gke_cluster = var.config.gitlab.gke.cluster
  gitlab_gke_cluster_location = var.config.gitlab.gke.location
  
  gitlab_server = var.config.gitlab.url

  gke_namespace_format = var.config.gitlab.runners.k8sNamespace
  gke_deployment_format = var.config.gitlab.runners.k8sDeployment
  gke_secret_format = var.config.gitlab.runners.k8sSecret
  gke_service_account_format = var.config.gitlab.runners.k8sServiceAccount
  gke_service_account_role_format = var.config.gitlab.runners.k8sServiceAccountRole
  gke_service_account_role_binding_format = var.config.gitlab.runners.k8sServiceAccountRoleBinding
  gcp_service_account_format = var.config.gitlab.runners.serviceAccount
  iam_permissions = lookup(var.config.gitlab.runners.serviceAccountPermissions, each.value.folder)
  gitlab_runner_version = var.config.gitlab.runners.version
}
*/
