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
  _trf_iam = flatten([
    for principal, roles in local.trf_iam : [
      for role in roles : {
        key       = "${principal}-${role}"
        principal = principal
        role      = role
      }
    ]
  ])
  trf_iam_additive = {
    for binding in local._trf_iam : binding.key => {
      role   = binding.role
      member = local.iam_principals[binding.principal]
    }
  }
  trf_iam_auth = {
    for binding in local._trf_iam :
    binding.role => local.iam_principals[binding.principal]...
  }
  transf_subnet = (
    local.use_shared_vpc
    ? var.network_config.subnet_self_links.orchestration
    : values(module.transf-vpc[0].subnet_self_links)[0]
  )
  transf_vpc = (
    local.use_shared_vpc
    ? var.network_config.network_self_link
    : module.transf-vpc[0].self_link
  )
}
