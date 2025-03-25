# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Stage outputs.

output "project_ids" {
  description = "Project id."
  value = merge(
    {
      central = module.central-project.project_id
      data_domains = { for k, v in module.dd-projects : k => {
        project_id               = v.project_id
        folder_id                = one([for kk, vv in module.dd-folders : vv.id if strcontains(kk, k)])
        data_products_project_id = { for kkk, vvv in module.dp-projects : kkk => one([vvv.project_id]) if strcontains(kkk, k) }
        }
      }
    }
  )
}

output "central_project_resources" {
  description = "Central project Resources."
  value = {
    policy-tags       = module.central-policy-tags.tags
    tag-templates-ids = module.central-tag-templates.data_catalog_tag_template_ids
  }
}
