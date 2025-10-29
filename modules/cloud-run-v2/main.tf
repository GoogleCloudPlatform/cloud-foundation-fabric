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
  _ctx_p = "$"
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local._ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  connector = (
    var.vpc_connector_create != null
    ? google_vpc_access_connector.connector[0].id
    : try(var.revision.vpc_access.connector, null)
  )
  _invoke_command = {
    JOB        = <<-EOT
      gcloud run jobs execute \
        --project ${var.project_id} \
        --region ${var.region} \
        --wait ${local.resource.name} \
        --args=
    EOT
    WORKERPOOL = ""
    SERVICE    = <<-EOT
    curl -H "Authorization: bearer $(gcloud auth print-identity-token)" \
        ${local.resource.uri} \
        -X POST -d 'data'
    EOT
  }
  invoke_command = local._invoke_command[var.type]

  location   = lookup(local.ctx.locations, var.region, var.region)
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)

  revision_name = (
    var.revision.name == null ? null : "${var.name}-${var.revision.name}"
  )
  _resource = {
    "JOB" : (
      var.managed_revision ?
      try(google_cloud_run_v2_job.job[0], null) : try(google_cloud_run_v2_job.job_unmanaged[0], null)
    )
    "WORKERPOOL" : (
      var.managed_revision ?
      try(google_cloud_run_v2_worker_pool.default_managed[0], null) : try(google_cloud_run_v2_worker_pool.default_unmanaged[0], null)
    )
    "SERVICE" : (
      var.managed_revision ?
      try(google_cloud_run_v2_service.service[0], null) : try(google_cloud_run_v2_service.service_unmanaged[0], null)
    )
  }
  resource = {
    id       = local._resource[var.type].id
    location = local._resource[var.type].location
    name     = local._resource[var.type].name
    project  = local._resource[var.type].project
    uri      = var.type == "SERVICE" ? local._resource[var.type].uri : ""
  }
}
