/**
 * Copyright 2026 Google LLC
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

# tfdoc:file:description Phase 2: Secret Manager.

# Each YAML file maps to one secret-manager module instance which can
# manage several secrets, as the module interface is a map of secrets.
# Secret names must be unique across files as they are merged in context.

locals {
  _secret_manager_raw = {
    for f in try(fileset(local.paths.secret_manager, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local.paths.secret_manager}/${f}")
    )
  }
}

module "secret-manager" {
  source     = "../secret-manager"
  for_each   = local._secret_manager_raw
  project_id = try(each.value.project_id, null)
  secrets    = try(each.value.secrets, {})
  context    = local.ctx_phase_2
}
