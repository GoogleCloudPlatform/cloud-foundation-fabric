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

# tfdoc:file:description Phase 3: Cloud Run services, jobs and worker pools.

locals {
  _cloud_run_raw = {
    for f in try(fileset(local.paths.cloud_run, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local.paths.cloud_run}/${f}")
    )
  }
}

module "cloud-run" {
  source                 = "../cloud-run-v2"
  for_each               = local._cloud_run_raw
  project_id             = try(each.value.project_id, null)
  name                   = try(each.value.name, each.key)
  region                 = each.value.region
  type                   = try(each.value.type, "SERVICE")
  binary_authorization   = try(each.value.binary_authorization, null)
  containers             = try(each.value.containers, {})
  deletion_protection    = try(each.value.deletion_protection, null)
  encryption_key         = try(each.value.encryption_key, null)
  job_config             = try(each.value.job_config, {})
  labels                 = try(each.value.labels, {})
  launch_stage           = try(each.value.launch_stage, null)
  managed_revision       = try(each.value.managed_revision, true)
  revision               = try(each.value.revision, {})
  service_account_config = try(each.value.service_account_config, {})
  service_config         = try(each.value.service_config, {})
  tag_bindings           = try(each.value.tag_bindings, {})
  volumes                = try(each.value.volumes, {})
  vpc_connector_create   = try(each.value.vpc_connector_create, null)
  workerpool_config      = try(each.value.workerpool_config, {})
  context                = local.ctx_phase_3
  iam                    = try(each.value.iam, {})
}
