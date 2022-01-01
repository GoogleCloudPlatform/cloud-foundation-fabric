/**
 * Copyright 2022 Google LLC
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

module "test" {
  source           = "../../../../modules/cloud-config-container/mysql"
  cloud_config     = var.cloud_config
  config_variables = var.config_variables
  image            = var.image
  kms_config       = var.kms_config
  mysql_config     = var.mysql_config
  mysql_data_disk  = var.mysql_data_disk
  mysql_password   = var.mysql_password
}
