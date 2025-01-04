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

# tfdoc:file:description Per-environment certificate resources.

locals {
  cas = flatten([
    for k, v in var.certificate_authorities : [
      for e in coalesce(v.environments, keys(var.environments)) : merge(v, {
        environment = e
        key         = "${e}-${k}"
        name        = k
      })
    ]
  ])
}

module "cas" {
  source                = "../../../modules/certificate-authority-service"
  for_each              = { for k in local.cas : k.key => k }
  project_id            = module.project[each.value.environment].project_id
  ca_configs            = each.value.ca_configs
  ca_pool_config        = each.value.ca_pool_config
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_by_principals     = each.value.iam_by_principals
  location              = each.value.location
}
