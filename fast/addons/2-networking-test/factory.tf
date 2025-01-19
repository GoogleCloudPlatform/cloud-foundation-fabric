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

# tfdoc:file:description Factory locals.

locals {
  _factory_i_data = {
    for f in try(fileset(var.factories_config.instances, "*.yaml"), []) :
    replace(f, ".yaml", "") => yamldecode(
      file("${var.factories_config.instances}/${f}")
    )
  }
  _factory_sa_data = {
    for f in try(fileset(var.factories_config.service_accounts, "*.yaml"), []) :
    replace(f, ".yaml", "") => yamldecode(
      file("${var.factories_config.service_accounts}/${f}")
    )
  }
  factory_instances = {
    for k, v in local._factory_i_data :
    lookup(v, "name", k) => merge(v, {
      image          = lookup(v, "image", null)
      metadata       = lookup(v, "metadata", {})
      tags           = lookup(v, "tags", ["ssh"])
      type           = lookup(v, "type", "e2-micro")
      user_data_file = lookup(v, "user_data_file", null)
      zones          = lookup(v, "zones", ["b"])
    })
  }
  factory_service_accounts = {
    for k, v in local._factory_sa_data :
    lookup(v, "name", k) => merge(v, {
      display_name      = lookup(v, "display_name", null)
      iam_project_roles = lookup(v, "iam_project_roles", {})
    })
  }
}
