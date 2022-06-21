/**
 * Copyright 2022 Google LLC
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
  supported_cicd_systems = ["gitlab", "github", "sourcerepo"]
  cicd_repositories = {
    for k, v in coalesce(var.cicd_repositories, {}) : k => merge(v,
      { group = join("/", slice(split("/", v.name), 0, length(split("/", v.name)) - 1)) },
      { name = element(split("/", v.name), length(split("/", v.name)) - 1) },
    { create_group = try(v.create_group, true) })
    if(
      v != null
      &&
      contains(local.supported_cicd_systems, try(v.type, ""))
    )
  }
  cicd_repositories_by_system = { for system in local.supported_cicd_systems : system => {
    for k, v in local.cicd_repositories : k => v if v.type == system
    }
  }
}

resource "tls_private_key" "cicd-modules-key" {
  algorithm = "ED25519"
}
