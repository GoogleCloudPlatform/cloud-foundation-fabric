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
          try(v.from.resources, []),
          try(v.to.resources, [])
        ]
      ],
      [
        for k, v in local.egress_policies : [
          try(v.from.resources, []),
          try(v.to.resources, [])
        ]
      ],
    ]
  ]))
  _project_ids = [
    for x in local._all_project_identifiers :
    trimprefix(x, "projects/")
    if can(regex("^projects/[a-z]+", x))
  ]
  project_number = {
    for x in data.google_cloud_asset_search_all_resources.projects.results :
    (trimprefix(x.name, "//cloudresourcemanager.googleapis.com/")) => x.project
  }
}

resource "google_access_context_manager_access_policy" "default" {
  count  = var.access_policy_create != null ? 1 : 0
  parent = var.access_policy_create.parent
  title  = var.access_policy_create.title
  scopes = var.access_policy_create.scopes
}

locals {

  cai_query = join(" OR ",
    formatlist("\"//cloudresourcemanager.googleapis.com/projects/%s\"", local._project_ids)
  )
}

data "google_cloud_asset_search_all_resources" "projects" {
  scope = "organizations/529325294915"
  asset_types = [
    "cloudresourcemanager.googleapis.com/Project"
  ]
  query = "name=${local.cai_query}"
}

output "cai" {
  value = {
    # cai_query      = local.cai_query
    # pid            = local._project_ids
    # result         = data.google_cloud_asset_search_all_resources.projects
    project_number = local.project_number
  }
}
