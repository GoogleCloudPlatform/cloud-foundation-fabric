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
  _ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  access_policy = try(
    google_access_context_manager_access_policy.default[0].name,
    var.access_policy
  )
  cai_query = join(" OR ",
    formatlist(
      "\"//cloudresourcemanager.googleapis.com/projects/%s\"",
      local._project_ids
    )
  )
  ctx = merge(local._ctx, {
    iam_principals_list = {
      for k, v in local._ctx.iam_principals : k => [v]
    }
    project_numbers = {
      for k, v in local._ctx.project_numbers : k => "projects/${v}"
    }
  })
  ctx_p = "$"
  do_cai_query = (
    var.project_id_search_scope == null
    ? false
    : length(local._project_ids) > 0
  )
  # collect project ids and convert them to numbers (project numbers is dynamic)
  _all_project_identifiers = distinct(flatten([
    for k, v in local.perimeters : [
      try(v.status.resources, []),
      try(v.spec.resources, []),
      [
        for _, vv in local.ingress_policies : [
          try(vv.from.resources, []),
          try(vv.to.resources, [])
        ]
      ],
      [
        for _, vv in local.egress_policies : [
          try(vv.from.resources, []),
          try(vv.to.resources, [])
        ]
      ],
    ]
  ]))
  _project_ids = [
    for x in local._all_project_identifiers :
    trimprefix(x, "projects/")
    if can(regex("^projects/[a-z]", x))
  ]
  project_numbers = (
    local.do_cai_query
    ? {
      for x in data.google_cloud_asset_search_all_resources.projects[0].results :
      (trimprefix(x.name, "//cloudresourcemanager.googleapis.com/")) => x.project
    }
    : {}
  )
}

resource "google_access_context_manager_access_policy" "default" {
  count  = var.access_policy_create != null ? 1 : 0
  parent = var.access_policy_create.parent
  title  = var.access_policy_create.title
  scopes = var.access_policy_create.scopes
}

data "google_cloud_asset_search_all_resources" "projects" {
  count = local.do_cai_query ? 1 : 0
  scope = var.project_id_search_scope
  asset_types = [
    "cloudresourcemanager.googleapis.com/Project"
  ]
  query = "name=${local.cai_query}"
}
