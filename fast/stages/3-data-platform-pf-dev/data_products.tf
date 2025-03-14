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
  _dp = flatten([
    for k, v in local._dd_raw : [
      for f in try(fileset("${local._dd_path}/${k}", "**/*.yaml"), []) : merge(
        yamldecode(file("${local._dd_path}/${k}/${f}")),
        {
          dd  = k
          dds = lookup(v, "short_name", k)
          key = trimsuffix(basename(f), ".yaml")
        }
      ) if !endswith(f, "_config.yaml")
    ]
  ])
  dp_projects = {
    for v in local._dp : "${v.dd}/${v.key}" => {
      name   = "${v.dds}-${lookup(v, "short_name", v.key)}-0"
      parent = v.dd
      iam = {
        for k, v in lookup(v, "iam", {}) : k => concat(
          v,
          k == "roles/owner" ? ["rw"] : (k == "roles/viewer" ? ["ro"] : [])
        )
      }
      iam_bindings              = lookup(v, "iam_bindings", {})
      iam_bindings_additive     = lookup(v, "iam_bindings_additive", {})
      iam_by_principals         = lookup(v, "iam_by_principals", {})
      services                  = lookup(v, "services", [])
      shared_vpc_service_config = lookup(v, "shared_vpc_service_config", null)
      automation = {
        project = v.dd
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
            display_name = "Automation for ${v.dds}/${v.key} data product (rw)."
          }
          ro = {
            display_name = "Automation for ${v.dds}/${v.key} data product (ro)."
          }
        }
      }
      service_accounts = lookup(v, "service_accounts", {})
    }
  }
}
