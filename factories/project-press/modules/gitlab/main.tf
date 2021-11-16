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

locals {
  namespaces = var.gitlab_project_runner ? {
    for env in var.environments : env => replace(replace(var.gke_namespace_format, "%project%", var.project_id), "%env%", env)
  } : {}
  secrets = var.gitlab_project_runner ? {
    for env in var.environments : env => replace(replace(var.gke_secret_format, "%project%", var.project_id), "%env%", env)
  } : {}
  k8s_service_accounts = var.gitlab_project_runner ? {
    for env in var.environments : env => {
      service_account = replace(replace(var.gke_service_account_format, "%project%", var.project_id), "%env%", env)
      role            = replace(replace(var.gke_service_account_role_format, "%project%", var.project_id), "%env%", env)
      role_binding    = replace(replace(var.gke_service_account_role_binding_format, "%project%", var.project_id), "%env%", env)
      secret          = replace(replace(var.gke_secret_format, "%project%", var.project_id), "%env%", env)
      deployment      = replace(replace(var.gke_deployment_format, "%project%", var.project_id), "%env%", env)
    }
  } : {}
  gcp_service_accounts = var.gitlab_project_runner ? {
    for env in var.environments : env => {
      service_account = replace(replace(var.gcp_service_account_format, "%project%", var.project_id), "%env%", env)
      project         = var.project_ids_full[index(var.environments, env)]
    }
  } : {}
  gcp_permissions = var.gitlab_project_runner ? flatten([
    for env in var.environments : { for role in var.iam_permissions[env] : "${env}-${role}" => {
      role = role
      env  = env
    } }
  ]) : [{}]
}

data "external" "gitlab_team" {
  program = ["python3", format("%s/../scripts/gitlab-users.py", path.root), format("%s/../config.yaml", path.root)]

  query = {
    team   = jsonencode(var.gitlab_team)
    owners = jsonencode(var.gitlab_owners)
  }
}

data "gitlab_user" "gitlab_users" {
  for_each = toset([for user, role in data.external.gitlab_team.result : user])

  username = each.value
}

data "gitlab_group" "gitlab_group" {
  provider = gitlab

  full_path = var.gitlab_project_group
}

resource "gitlab_project" "gitlab_project" {
  provider = gitlab

  name         = var.gitlab_project_id
  namespace_id = data.gitlab_group.gitlab_group.id
}

resource "gitlab_project_membership" "gitlab_project_members" {
  for_each = data.external.gitlab_team.result

  project_id   = gitlab_project.gitlab_project.id
  user_id      = data.gitlab_user.gitlab_users[each.key].id
  access_level = each.value
}

resource "kubernetes_namespace" "namespaces" {
  for_each = local.namespaces
  metadata {
    name = each.value
  }
}

resource "google_service_account" "gcp_service_accounts" {
  for_each = local.gcp_service_accounts

  project      = each.value.project
  account_id   = each.value.service_account
  display_name = format("Gitlab Runner (%s)", each.key)
}

resource "google_project_iam_member" "gcp_service_accounts_permissions" {
  for_each = merge(local.gcp_permissions...)

  project = each.value.project
  role    = each.value.role

  member = format("serviceAccount:%s", google_service_account.gcp_service_accounts[each.value.env].email)
}


resource "google_service_account_iam_member" "service_account_iam" {
  for_each = local.gcp_service_accounts

  service_account_id = google_service_account.gcp_service_accounts[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = format("serviceAccount:%s.svc.id.goog[%s/%s]", var.gitlab_gke_project, kubernetes_namespace.namespaces[each.key].metadata.0.name, kubernetes_service_account.k8s_service_accounts[each.key].metadata.0.name)
}

resource "kubernetes_service_account" "k8s_service_accounts" {
  for_each = local.k8s_service_accounts

  metadata {
    name      = each.value.service_account
    namespace = kubernetes_namespace.namespaces[each.key].id
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.gcp_service_accounts[each.key].email
    }
  }

  secret {
    name = kubernetes_secret.registration_token[each.key].metadata.0.name
  }

  automount_service_account_token = true
}

resource "kubernetes_role" "k8s_role" {
  for_each = local.k8s_service_accounts

  metadata {
    name      = each.value.role
    namespace = kubernetes_namespace.namespaces[each.key].id
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/exec", "secrets"]
    verbs      = ["get", "list", "watch", "create", "patch", "delete"]
  }
}

resource "kubernetes_role_binding" "k8s_role_binding" {
  for_each = local.k8s_service_accounts

  metadata {
    name      = each.value.role_binding
    namespace = kubernetes_namespace.namespaces[each.key].id
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = each.value.role
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.k8s_service_accounts[each.key].metadata.0.name
    namespace = kubernetes_namespace.namespaces[each.key].id
  }
}

resource "kubernetes_secret" "registration_token" {
  for_each = local.k8s_service_accounts

  metadata {
    name      = each.value.secret
    namespace = kubernetes_namespace.namespaces[each.key].id
  }

  data = {
    runner-registration-token = gitlab_project.gitlab_project.runners_token
    runner-token              = ""
  }
}

data "template_file" "helm_parameters" {
  for_each = local.k8s_service_accounts

  template = file(format("%s/runner.yml.tpl", path.module))
  vars = {
    gitlab_server   = var.gitlab_server
    service_account = kubernetes_service_account.k8s_service_accounts[each.key].metadata.0.name
    secret          = kubernetes_secret.registration_token[each.key].metadata.0.name
    namespace       = kubernetes_namespace.namespaces[each.key].id
    project         = var.gitlab_project_id
    tag             = each.key
  }
}

resource "helm_release" "runners" {
  for_each = local.k8s_service_accounts

  name      = each.value.deployment
  namespace = kubernetes_namespace.namespaces[each.key].id

  repository = "https://charts.gitlab.io"

  chart   = "gitlab-runner"
  version = var.gitlab_runner_version

  values = [data.template_file.helm_parameters[each.key].rendered]
}
