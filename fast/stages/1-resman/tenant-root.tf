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
  count         = var.root_node != null ? 1 : 0
  id            = var.root_node
  folder_create = false
  # additive bindings via delegated IAM grant set in stage 0
  iam_bindings_additive = local.iam_bindings_additive
  logging_sinks = {
    for name, attrs in local.log_sinks : name => {
      bq_partitioned_table = attrs.type == "bigquery"
      destination          = local.log_sink_destinations[name].id
      filter               = attrs.filter
      type                 = attrs.type
    }
  }
}

module "automation-project" {
  source         = "../../../modules/project"
  count          = var.root_node != null ? 1 : 0
  name           = var.automation.project_id
  project_create = false
  # do not assign tagViewer or tagUser roles here on tag keys and values as
  # they are managed authoritatively and will break multitenant stages
  tags = merge(local.tags, {
    (var.tag_names.context) = {
      description = "Resource management context."
      iam         = try(local.tags.context.iam, {})
      values = {
        data = {
          iam         = try(local.tags.context.values.data.iam, {})
          description = try(local.tags.context.values.data.description, null)
        }
        gke = {
          iam         = try(local.tags.context.values.gke.iam, {})
          description = try(local.tags.context.values.gke.description, null)
        }
        gcve = {
          iam         = try(local.tags.context.values.gcve.iam, {})
          description = try(local.tags.context.values.gcve.description, null)
        }
        networking = {
          iam         = try(local.tags.context.values.networking.iam, {})
          description = try(local.tags.context.values.networking.description, null)
        }
        project-factory = {
          iam         = try(local.tags.context.values.project-factory.iam, {})
          description = try(local.tags.context.values.project-factory.description, null)
        }
        sandbox = {
          iam         = try(local.tags.context.values.sandbox.iam, {})
          description = try(local.tags.context.values.sandbox.description, null)
        }
        security = {
          iam         = try(local.tags.context.values.security.iam, {})
          description = try(local.tags.context.values.security.description, null)
        }
      }
    }
    (var.tag_names.environment) = {
      description = "Environment definition."
      iam         = try(local.tags.environment.iam, {})
      values = {
        development = {
          iam = try(local.tags.environment.values.development.iam, {})
          iam_bindings = {
            pf = {
              members = [module.branch-pf-sa.iam_email]
              role    = "roles/resourcemanager.tagUser"
            }
          }
          description = try(local.tags.environment.values.development.description, null)
        }
        production = {
          iam = try(local.tags.environment.values.production.iam, {})
          iam_bindings = {
            pf = {
              members = [module.branch-pf-sa.iam_email]
              role    = "roles/resourcemanager.tagUser"
            }
          }
          description = try(local.tags.environment.values.production.description, null)
        }
      }
    }
  })
}
