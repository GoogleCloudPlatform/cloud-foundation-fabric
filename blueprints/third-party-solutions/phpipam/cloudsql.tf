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

# Set up CloudSQL
module "cloudsql" {
  source              = "../../../modules/cloudsql-instance"
  project_id          = module.project.project_id
  name                = "${var.prefix}-mysql"
  database_version    = local.cloudsql_conf.database_version
  deletion_protection = var.deletion_protection
  databases           = [local.cloudsql_conf.db]
  network             = local.network
  prefix              = var.prefix
  region              = var.region
  tier                = local.cloudsql_conf.tier
  users = {
    "${local.cloudsql_conf.user}" = var.cloudsql_password
  }
}
