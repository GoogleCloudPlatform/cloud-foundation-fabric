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

module "root-folder" {
  source        = "../../../modules/folder"
  count         = var.root_node == true ? 1 : 0
  id            = var.root_node
  folder_create = false
  # additive bindings via delegated IAM grant set in stage 0
  iam_bindings_additive = local.iam_bindings_additive
}

module "automation-project" {
  source         = "../../../modules/project"
  count          = var.root_node == true ? 1 : 0
  name           = var.automation.project_id
  project_create = false
  # do not assign tagViewer or tagUser roles here on tag keys and values as
  # they are managed authoritatively and will break multitenant stages
  tags = merge(local.tags, {
    (var.tag_names.context) = {
      description = "Resource management context."
      iam         = {}
      values = {
        data       = {}
        gke        = {}
        gcve       = {}
        networking = {}
        sandbox    = {}
        security   = {}
      }
    }
    (var.tag_names.environment) = {
      description = "Environment definition."
      iam         = {}
      values = {
        development = {}
        production  = {}
      }
    }
  })
}
