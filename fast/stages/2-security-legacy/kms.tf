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

# tfdoc:file:description Per-environment KMS.

locals {
  _kms_locations = distinct(flatten([
    for k, v in var.kms_keys : v.locations
  ]))
  kms_keyrings = flatten([
    for k, v in var.environments : [
      for l in local._kms_locations : {
        environment = k
        key         = "${v.short_name}-${l}"
        location    = l
        name        = "${v.short_name}-${l}"
      }
    ]
  ])
  # list of locations with keys
  # map { location -> { key_name -> key_details } }
  kms_keys = {
    for loc in local._kms_locations :
    loc => {
      for k, v in var.kms_keys : k => v if contains(v.locations, loc)
    }
  }
}

module "kms" {
  for_each   = { for k in local.kms_keyrings : k.key => k }
  source     = "../../../modules/kms"
  project_id = module.project[each.value.environment].project_id
  keyring = {
    location = each.value.location
    name     = each.value.name
  }
  keys = local.kms_keys[each.value.location]
}
