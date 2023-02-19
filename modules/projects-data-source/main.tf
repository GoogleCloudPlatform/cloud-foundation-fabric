/**
 * Copyright 2023 Google LLC
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
  _ignore_folder_numbers = [for folder_id in var.ignore_folders : trimprefix(folder_id, "folders/")]
  _ignore_folders_query  = join(" AND NOT folders:", concat([""], local._ignore_folder_numbers))
  query = var.query != "" ? (
    format("%s%s", var.query, local._ignore_folders_query)
    ) : (
    format("%s%s", var.query, trimprefix(local._ignore_folders_query, " AND "))
  )

  ignore_patterns = [for item in var.ignore_projects : "^${replace(item, "*", ".*")}$"]
  ignore_regexp   = length(local.ignore_patterns) > 0 ? join("|", local.ignore_patterns) : "^NO_PROJECTS_TO_IGNORE$"
  projects_after_ignore = [for item in data.google_cloud_asset_resources_search_all.projects.results : item if(
    length(concat(try(regexall(local.ignore_regexp, trimprefix(item.project, "projects/")), []), try(regexall(local.ignore_regexp, trimprefix(item.name, "//cloudresourcemanager.googleapis.com/projects/")), []))) == 0
    ) || contains(var.include_projects, trimprefix(item.name, "//cloudresourcemanager.googleapis.com/projects/")) || contains(var.include_projects, trimprefix(item.project, "projects/"))
  ]
}

data "google_cloud_asset_resources_search_all" "projects" {
  provider = google-beta
  scope    = var.parent
  asset_types = [
    "cloudresourcemanager.googleapis.com/Project"
  ]
  query = local.query
}
