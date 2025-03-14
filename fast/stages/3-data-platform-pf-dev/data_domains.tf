/**
 * Copyright 2025 Google LLC
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
  _dd_path = try(pathexpand(var.factories_config.data_domains), null)
  _dd_raw = {
    for f in try(fileset(local._dd_path, "**/_config.yaml"), []) :
    dirname(f) => yamldecode(file("${local._dd_path}/${f}"))
  }
  dd_folders = {
    for k, v in local._dd_raw : k => {
      name                  = v.name
      parent                = local.folder_id
      iam                   = try(v.folder_config.iam, {})
      iam_bindings          = try(v.folder_config.iam_bindings, {})
      iam_bindings_additive = try(v.folder_config.iam_bindings_additive, {})
      iam_by_principals     = try(v.folder_config.iam_by_principals, {})
    }
  }
  dd_projects = {
    for k, v in local._dd_raw : k => {
      name   = "${lookup(v, "short_name", k)}-shared-0"
      parent = k
      iam = {
        for k, v in lookup(v, "iam", {}) : k => concat(
          v,
          k == "roles/owner" ? ["rw"] : (k == "roles/viewer" ? ["ro"] : [])
        )
      }
      iam_bindings              = try(v.project_config.iam_bindings, {})
      iam_bindings_additive     = try(v.project_config.iam_bindings_additive, {})
      iam_by_principals         = try(v.project_config.iam_by_principals, {})
      services                  = try(v.project_config.services, [])
      shared_vpc_service_config = try(v.project_config.shared_vpc_service_config, null)
      automation = {
        project = module.central-project.project_id
        bucket = {
          location   = local.location
          prefix     = local.prefix
          versioning = true
          iam = {
            "roles/storage.objectCreator" = ["rw"]
            "roles/storage.objectViewer"  = ["ro"]
          }
        }
        service_accounts = {
          rw = {
            display_name = "Automation for ${k} data domain (rw)."
          }
          ro = {
            display_name = "Automation for ${k} data domain (ro)."
          }
        }
      }
    }
  }
}
output "foo" {
  value = {
    dd = local.dd_projects
    dp = local.dp_projects
    pd = module.factory.foo
  }
}
