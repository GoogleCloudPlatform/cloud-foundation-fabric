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

# tfdoc:file:description Read and process YaML factory files and variables.
locals {
  _network_factory_path = try(
    pathexpand(var.factories_config.vpcs), null
  )
  _network_factory_files = try(
    fileset(local._network_factory_path, "**/*.yaml"),
    []
  )

  _network_projects_from_files = {
    for f in local._network_factory_files :
    f => yamldecode(file("${local._network_factory_path}/${f}"))
  }

  _network_projects = {
    for _, v in local._network_projects_from_files :
    v.project_config.name => v
  }

  network_projects = merge(local._network_projects, var.network_project_config)
}
