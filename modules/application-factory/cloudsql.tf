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

# tfdoc:file:description Phase 3: Cloud SQL instances.

locals {
  _cloudsql_raw = {
    for f in try(fileset(local.paths.cloudsql, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local.paths.cloudsql}/${f}")
    )
  }
}

module "cloudsql" {
  source   = "../cloudsql-instance"
  for_each = local._cloudsql_raw
  project_id = lookup(
    local.ctx.project_ids, try(each.value.project_id, ""), try(each.value.project_id, null)
  )
  name             = try(each.value.name, each.key)
  database_version = each.value.database_version
  tier             = each.value.tier
  region = lookup(
    local.ctx.locations, each.value.region, each.value.region
  )
  prefix                        = try(each.value.prefix, null)
  activation_policy             = try(each.value.activation_policy, "ALWAYS")
  availability_type             = try(each.value.availability_type, "ZONAL")
  backup_configuration          = try(each.value.backup_configuration, null)
  collation                     = try(each.value.collation, null)
  connector_enforcement         = try(each.value.connector_enforcement, null)
  data_cache                    = try(each.value.data_cache, false)
  databases                     = try(each.value.databases, null)
  disk_autoresize_limit         = try(each.value.disk_autoresize_limit, 0)
  disk_size                     = try(each.value.disk_size, null)
  disk_type                     = try(each.value.disk_type, "PD_SSD")
  edition                       = try(each.value.edition, "ENTERPRISE")
  encryption_key_name           = try(each.value.encryption_key_name, null)
  flags                         = try(each.value.flags, null)
  gcp_deletion_protection       = try(each.value.gcp_deletion_protection, true)
  terraform_deletion_protection = try(each.value.terraform_deletion_protection, true)
  insights_config               = try(each.value.insights_config, null)
  labels                        = try(each.value.labels, null)
  maintenance_config            = try(each.value.maintenance_config, {})
  network_config                = each.value.network_config
  replicas                      = try(each.value.replicas, {})
  root_password                 = try(each.value.root_password, {})
  ssl                           = try(each.value.ssl, {})
  time_zone                     = try(each.value.time_zone, null)
  users                         = try(each.value.users, {})
}
