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

variable "gitlab_project_id" {
  type        = string
  description = "Gitlab project ID"
}

variable "gitlab_project_group" {
  type        = string
  description = "Gitlab project group ID"
}

variable "gitlab_project_runner" {
  type        = bool
  description = "Whether to provision a Gitlab runner"
}

variable "project_id" {
  type        = string
  description = "Project ID"
}

variable "project_ids_full" {
  type        = list(string)
  description = "Project IDs (full)"
}

variable "environments" {
  type        = list(string)
  description = "Environments"
}

variable "gitlab_gke_project" {
  type        = string
  description = "Google Cloud project where Gitlab cluster resides in"
}

variable "gitlab_gke_cluster" {
  type        = string
  description = "GKE cluster name where Gitlab is installed in"
}

variable "gitlab_gke_cluster_location" {
  type        = string
  description = "Region for gitlab_gke_cluster"
}

variable "gitlab_server" {
  type        = string
  description = "Gitlab server URL"
}

variable "gke_namespace_format" {
  type        = string
  description = "GKE namespace format"
}

variable "gke_deployment_format" {
  type        = string
  description = "GKE runner deployment format"
}

variable "gke_secret_format" {
  type        = string
  description = "GKE secret format"
}

variable "gke_service_account_format" {
  type        = string
  description = "GKE service account format"
}

variable "gke_service_account_role_format" {
  type        = string
  description = "GKE service account role format"
}

variable "gke_service_account_role_binding_format" {
  type        = string
  description = "GKE service account role binding format"
}

variable "gcp_service_account_format" {
  type        = string
  description = "GCP service account format"
}

variable "iam_permissions" {
  type        = map(list(string))
  description = "Roles to grant the Gitlab runner GCP service account in the project"
}

variable "gitlab_runner_version" {
  type        = string
  description = "Gitlab runner Helm chart version" # https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/master/CHANGELOG.md
}

variable "gitlab_team" {
  type        = map(any)
  description = "Gitlab team"
}

variable "gitlab_team_permissions" {
  type        = map(any)
  description = "Gitlab team permissions"
}

variable "gitlab_owners" {
  type        = list(string)
  description = "Gitlab owner"
}
