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

# tfdoc:file:description IAM bindings, roles and audit logging resources.

locals {
  group_iam_roles = distinct(flatten(values(var.group_iam)))
  group_iam = {
    for r in local.group_iam_roles : r => [
      for k, v in var.group_iam : "group:${k}" if try(index(v, r), null) != null
    ]
  }
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local.group_iam))) :
    role => concat(
      try(var.iam[role], []),
      try(local.group_iam[role], [])
    )
  }
}

resource "google_folder_iam_binding" "authoritative" {
  for_each = local.iam
  folder   = local.folder.name
  role     = each.key
  members  = each.value
}
