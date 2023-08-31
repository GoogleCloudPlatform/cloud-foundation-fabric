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
  _drp_iam = flatten([
    for principal, roles in local.drp_iam : [
      for role in roles : {
        key       = "${principal}-${role}"
        principal = principal
        role      = role
      }
    ]
  ])
  drp_iam_additive = {
    for binding in local._drp_iam : binding.key => {
      role   = binding.role
      member = local.iam_principals[binding.principal]
    }
  }
  drp_iam_auth = {
    for binding in local._drp_iam :
    binding.role => local.iam_principals[binding.principal]...
  }
}
