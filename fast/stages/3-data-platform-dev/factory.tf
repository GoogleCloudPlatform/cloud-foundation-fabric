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
  _dd = {
    for k, v in local._dd_raw : k => {
      short_name = lookup(v, "short_name", reverse(split("/", k))[0])
      folder_config = try(v.folder_config.name, null) == null ? null : merge(
        {
          iam                   = {}
          iam_bindings          = {}
          iam_bindings_additive = {}
          iam_by_principals     = {}
        }, v.folder_config
      )
      project_config = {
        name                  = try(v.project_config.name, k)
        services              = try(v.project_config.services, [])
        iam                   = try(v.project_config.iam, {})
        iam_bindings          = try(v.project_config.iam_bindings, {})
        iam_bindings_additive = try(v.project_config.iam_bindings_additive, {})
        iam_by_principals     = try(v.project_config.iam_by_principals, {})
      }
      data_products = {
        for f in try(fileset("${local._dd_path}/${k}", "**/*.yaml"), []) :
        trimsuffix(basename(f), ".yaml") => yamldecode(file("${local._dd_path}/${k}/${f}"))
        if !endswith(f, "_config.yaml")
      }
    }
  }
}
output "foo" {
  value = local._dd
}
