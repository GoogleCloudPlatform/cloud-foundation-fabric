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
  dd_composer = {
    for k, v in local.data_domains : k => v
    if try(v.deploy.composer, null) == true
  }
}

module "dd-composer-sa" {
  source      = "../../../modules/iam-service-account"
  for_each    = local.dd_composer
  project_id  = module.dd-projects[each.key].project_id
  prefix      = local.prefix
  name        = "${each.value.short_name}-cmp-sa"
  description = "Composer Service Account."
}
