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

# tfdoc:file:description Folder-level SCC mute configurations.

locals {
  _scc_mute_configs_factory_path = pathexpand(coalesce(var.factories_config.scc_mute_configs, "-"))
  _scc_mute_configs_factory_data_raw = merge([
    for f in try(fileset(local._scc_mute_configs_factory_path, "*.yaml"), []) :
    yamldecode(file("${local._scc_mute_configs_factory_path}/${f}"))
  ]...)
  _scc_mute_configs_factory_data = {
    for k, v in local._scc_mute_configs_factory_data_raw :
    k => {
      description = try(v.description, null)
      filter      = v.filter
      type        = try(v.type, "DYNAMIC")
    }
  }
  _scc_mute_configs = merge(
    local._scc_mute_configs_factory_data,
    var.scc_mute_configs
  )
  scc_mute_configs = {
    for k, v in local._scc_mute_configs :
    k => merge(v, {
      name   = k
      parent = local.folder_id
    })
  }
}

resource "google_scc_v2_folder_mute_config" "scc_mute_configs" {
  for_each       = local.scc_mute_configs
  folder         = replace(local.folder_id, "folders/", "")
  location       = "global"
  mute_config_id = each.key
  description    = each.value.description
  filter         = each.value.filter
  type           = each.value.type
}
