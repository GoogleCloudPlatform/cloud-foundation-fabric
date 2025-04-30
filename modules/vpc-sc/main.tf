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
  access_policy = try(
    google_access_context_manager_access_policy.default[0].name,
    var.access_policy
  )

  # collect project ids and convert them to numbers
  _all_project_identifiers = distinct(flatten([
    for k, v in local.perimeters : [
      try(v.status.resources, []),
      try(v.spec.resources, []),
      [
        for k, v in local.ingress_policies : [
          try(v.from.resources),
          try(v.to.resources)
        ]
      ],
      [
        for k, v in local.egress_policies : [
          try(v.from.resources),
          try(v.to.resources)
        ]
      ],
    ]
  ]))
  _project_ids = toset([
    for x in local._all_project_identifiers :
    x
    if can(regex("^projects/[a-z]+", x))
  ])
  project_number = {
    for k, v in data.google_project.project :
    k => "projects/${v.number}"
  }
}

resource "google_access_context_manager_access_policy" "default" {
  count  = var.access_policy_create != null ? 1 : 0
  parent = var.access_policy_create.parent
  title  = var.access_policy_create.title
  scopes = var.access_policy_create.scopes
}

data "google_project" "project" {
  for_each   = local._project_ids
  project_id = trimprefix(each.value, "projects/")
}
