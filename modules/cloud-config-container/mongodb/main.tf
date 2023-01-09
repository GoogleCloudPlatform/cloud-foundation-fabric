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

locals {
  cloud_config = templatefile(local.template, merge(var.config_variables, {
    image                 = var.image
    healthcheck_image     = var.healthcheck_image
    startup_image         = var.startup_image
    exporter_image        = var.exporter_image
    monitoring_image      = var.monitoring_image
    replica_set           = var.replica_set
    mongo_config          = var.mongo_config
    mongo_data_disk       = var.mongo_data_disk
    mongo_port            = var.mongo_port
    admin_username        = var.admin_username
    admin_password_secret = var.admin_password_secret
    keyfile_secret        = var.keyfile_secret
    artifact_registries   = var.artifact_registries
    dns_zone              = var.dns_zone
  }))
  template = (
    var.cloud_config == null
    ? "${path.module}/cloud-config.yaml"
    : var.cloud_config
  )
}
