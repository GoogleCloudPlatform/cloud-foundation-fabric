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

locals {
  o_dd_iac_sa = {
    for k in keys(module.dd-automation-sa) :
    split("/", k)[0] => k...
  }
  o_dd_sa = {
    for k in keys(module.dd-service-accounts) :
    split("/", k)[0] => k...
  }
  o_dp = {
    for k, v in local.data_products :
    v.dd => k...
  }
  o_dp_iac_sa = {
    for k in keys(module.dp-automation-sa) :
    join("/", slice(split("/", k), 0, 2)) => k...
  }
}

output "data_domains" {
  description = "Data domain attributes."
  value = {
    for k, v in local.data_domains : k => {
      automation = v.automation == null ? null : {
        bucket = module.dd-automation-bucket[k].name
        service_accounts = {
          for vv in lookup(local.o_dd_iac_sa, k, []) :
          split("/", vv)[1] => module.dd-automation-sa[vv].email
        }
      }
      data_products = {
        for vv in lookup(local.o_dp, k, []) : split("/", vv)[1] => {
          project = {
            id     = module.dp-projects[vv].project_id
            number = module.dp-projects[vv].number
          }
          automation = local.data_products[vv].automation == null ? null : {
            bucket = module.dp-automation-bucket[vv].name
            service_accounts = {
              for vvv in lookup(local.o_dp_iac_sa, vv, []) :
              split("/", vvv)[2] => module.dp-automation-sa[vvv].email
            }
          }
        }
      }
      folder          = module.dd-folders[k].id
      folder_products = module.dd-dp-folders[k].id
      project = {
        id     = module.dd-projects[k].project_id
        number = module.dd-projects[k].number
      }
      service_accounts = {
        for vv in lookup(local.o_dd_sa, k, []) :
        split("/", vv)[1] => module.dd-service-accounts[vv].email
      }
    }
  }
}

output "central_project" {
  description = "Central project attributes."
  value = {
    aspect_types = module.central-aspect-types.ids
    policy_tags  = module.central-policy-tags.tags
    secure_tags = {
      for k, v in module.central-project.tag_values : k => v.id
    }
    project = {
      id     = module.central-project.project_id
      number = module.central-project.number
    }
  }
}
