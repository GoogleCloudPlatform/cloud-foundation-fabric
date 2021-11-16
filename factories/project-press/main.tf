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
  config           = yamldecode(var.config_file == "" ? file("${path.module}/config/config.yaml") : file(var.config_file))
  project_files    = fileset(var.project_files_path == "" ? "${path.module}/projects/" : var.project_files_path, "*.yaml")
  projects_decoded = [for file in local.project_files : yamldecode(file("${path.module}/projects/${file}"))]
  projects         = { for project in local.projects_decoded : project.project.projectId => project.project if project.project.status == "active" }
}

provider "google" {
  project = local.config.seedProject
}

provider "google-beta" {
  project = local.config.seedProject
}

provider "googleworkspace" {
  customer_id = local.config.cloudIdentityCustomerId
}

module "main" {
  source = "./modules/main"

  projects = local.projects
  config   = local.config
}
