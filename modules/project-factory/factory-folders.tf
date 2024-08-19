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

# tfdoc:file:description Folder hierarchy factory locals.

locals {
  _folders_path = try(
    pathexpand(var.factories_config.folders_data_path), null
  )
  _folders = {
    for f in local._hierarchy_files : dirname(f) => yamldecode(file(
      "${coalesce(var.factories_config.folders_data_path, "-")}/${f}"
    ))
  }
  _hierarchy_files = try(
    fileset(local._folders_path, "**/_config.yaml"),
    []
  )
  folders = {
    for key, data in local._folders : key => merge(data, {
      key        = key
      level      = length(split("/", key))
      parent_key = dirname(key)
    })
  }
  hierarchy = merge(
    { for k, v in module.hierarchy-folder-lvl-1 : k => v.id },
    { for k, v in module.hierarchy-folder-lvl-2 : k => v.id },
    { for k, v in module.hierarchy-folder-lvl-3 : k => v.id },
  )
}
