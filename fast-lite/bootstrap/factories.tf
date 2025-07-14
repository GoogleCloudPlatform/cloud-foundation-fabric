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
  _data = {
    context = try(
      yamldecode(file(local._paths.context)), {}
    )
    # folders = {}
    organization = merge(
      # organization config
      {
        config = try(
          yamldecode(file("${local._paths.organization}/.config.yaml")), {}
        )
      },
      # custom roles, org policies, tags
      {
        for attr in ["custom-roles", "org-policies", "tags"] :
        replace(attr, "-", "_") => {
          for f in try(
            fileset("${local._paths.organization}/${attr}", "**/*.yaml"), []
            ) : trimsuffix(f, ".yaml") => yamldecode(file(
              "${local._paths.organization}/${attr}/${f}"
          ))
        }
      }
    )
    project_defaults = try(
      yamldecode(file(local._paths.files.project_defaults)), {}
    )
    # projects = {}
  }
  _paths = {
    for k, v in var.factories_config : k => try(pathexpand(v), null)
  }
}
output "foo" {
  value = {
    data  = local._data
    paths = local._paths
  }
}
