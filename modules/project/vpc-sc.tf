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

# tfdoc:file:description VPC-SC project-level perimeter configuration.

locals {
  vpc_sc_perimeter = try(var.vpc_sc.perimeter_name, null)
  vpc_sc_dry_run   = try(var.vpc_sc.is_dry_run, null)
}

# use only if the vpc-sc module has a lifecycle block to ignore resources

resource "google_access_context_manager_service_perimeter_resource" "default" {
  for_each = toset(
    local.vpc_sc_perimeter == null || local.vpc_sc_dry_run == true
    ? []
    : compact([var.vpc_sc.perimeter_name])
  )
  perimeter_name = lookup(local.ctx.vpc_sc_perimeters, each.key, each.key)
  resource       = "projects/${local.project.number}"
}

resource "google_access_context_manager_service_perimeter_dry_run_resource" "default" {
  for_each = toset(
    local.vpc_sc_perimeter != null && local.vpc_sc_dry_run == true
    ? compact([var.vpc_sc.perimeter_name])
    : []
  )
  perimeter_name = lookup(local.ctx.vpc_sc_perimeters, each.key, each.key)
  resource       = "projects/${local.project.number}"
}
