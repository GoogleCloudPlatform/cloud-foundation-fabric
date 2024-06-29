/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description Top-level folders IAM profiles.

locals {
  # derive folder-level bindings from role names
  folder_profile_iam = {
    for k, v in local._folder_profile_iam_roles : k => {
      # get the set of combined role names
      for role in distinct(concat(v.ro, v.rw, v.user)) : role => distinct(concat(
        # combine user principals with ro and rw sa
        try(local.top_level_folders[k]["iam"][role], []),
        !contains(v.ro, role) ? [] : [module.top-level-r-sa[k].iam_email],
        !contains(v.rw, role) ? [] : [module.top-level-sa[k].iam_email],
      ))
    }
  }
  # derive org-level bindings from roles names
  folder_profile_org_iam = flatten([
    for k, v in local._folder_profile_iam_roles : [
      for binding in v.rw_org : {
        condition = (
          try(binding.condition, null) == null
          ? null
          : {
            description = "${binding.condition.description} ${k}."
            expression  = binding.condition.expression
            title       = "${binding.condition.title}_${k}"
          }
        )
        folder = k
        key    = "${k}-${binding.role}"
        role   = binding.role
      }
    ]
  ])
  # recombine all role names at folder level
  _folder_profile_iam_roles = {
    for k, v in local.top_level_folders : k => {
      ro = concat(
        try(local._folder_profile_tpl_folder["_BASE"]["ro"], []),
        try(local._folder_profile_tpl_folder[v.fast_profile.type]["ro"], [])
      )
      rw = concat(
        try(local._folder_profile_tpl_folder["_BASE"]["rw"], []),
        try(local._folder_profile_tpl_folder[v.fast_profile.type]["rw"], [])
      )
      rw_org = concat(
        try(local._folder_profile_tpl_org["_BASE"], []),
        try(local._folder_profile_tpl_org[v.fast_profile.type], [])
      )
      user = keys(v.iam)
    } if v.fast_profile != null
  }
  # IAM template for folder-level roles
  _folder_profile_tpl_folder = {
    _BASE = {
      ro = [
        "roles/viewer",
        "roles/resourcemanager.folderViewer"
      ]
      rw = [
        "roles/logging.admin",
        "roles/owner",
        "roles/resourcemanager.folderAdmin",
        "roles/resourcemanager.projectCreator",
        var.custom_roles.service_project_network_admin
      ]
    }
    NETWORKING = {
      rw = [
        "roles/compute.xpnAdmin"
      ]
    }
  }
  # IAM template for rw sa org-level roles
  _folder_profile_tpl_org = {
    NETWORKING = [
      { role = "roles/cloudasset.viewer" },
      { role = "roles/compute.orgFirewallPolicyAdmin" },
      { role = "roles/compute.xpnAdmin" }
    ]
    PROJECT_FACTORY = [
      {
        role = "roles/orgpolicy.policyAdmin"
        condition = {
          title       = "pf_org_policy_admin"
          description = "Project factory org policy admin for"
          expression  = <<-END
            resource.matchTag('${local.tag_root}/${var.tag_names.context}', 'project-factory')
          END
        }
      }
    ]
    SECURITY = [
      { role = "roles/accesscontextmanager.policyAdmin" },
      { role = "roles/cloudasset.viewer" }
    ]
  }
}
