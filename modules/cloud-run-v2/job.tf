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

resource "google_cloud_run_v2_job_iam_binding" "binding" {
  for_each = var.type == "JOB" ? var.iam : {}
  project  = local.resource.project
  location = local.resource.location
  name     = local.resource.name
  role     = lookup(local.ctx.custom_roles, each.key, each.key)
  members  = [for member in each.value : lookup(local.ctx.iam_principals, member, member)]
}
