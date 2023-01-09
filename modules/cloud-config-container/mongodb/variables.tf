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

variable "admin_password_secret" {
  description = "Optional Secret Manager password for administration user. Leave null if no authentication is used."
  type        = string
  default     = null
}

variable "admin_username" {
  description = "Optional username for administration user. Leave null if no authentication is used."
  type        = string
  default     = "admin"
}

variable "artifact_registries" {
  description = "List of Artifact registry hostname to configure for Docker authentication."
  type        = list(string)
  default     = ["europe-west4-docker.pkg.dev", "europe-docker.pkg.dev", "us-docker.pkg.dev", "asia-docker.pkg.dev"]
}

variable "cloud_config" {
  description = "Cloud config template path. If null default will be used."
  type        = string
  default     = null
}

variable "config_variables" {
  description = "Additional variables used to render the cloud-config template."
  type        = map(any)
  default     = {}
}

variable "dns_zone" {
  description = "DNS zone for MongoDB SRV records."
  type        = string
  default     = null
}

variable "exporter_image" {
  description = "Prometheus metrics exporter image."
  type        = string
  default     = "percona/mongodb_exporter:0.36"
}

variable "healthcheck_image" {
  description = "Health check container image."
  type        = string
  default     = null
}

variable "image" {
  description = "MongoDB container image."
  type        = string
  default     = "mongo:6.0"
}

variable "keyfile_secret" {
  description = "Secret Manager secret for keyfile used for authentication between replica set members."
  type        = string
  default     = null
}

variable "mongo_config" {
  description = "MongoDB configuration file content, if null container default will be used."
  type        = string
  default     = null
}

variable "mongo_data_disk" {
  description = "MongoDB data disk name in /dev/disk/by-id/ including the google- prefix. If null the boot disk will be used for data."
  type        = string
  default     = null
}

variable "mongo_port" {
  description = "Port to use for MongoDB. Defaults to 27017."
  type        = number
  default     = 27017
}

variable "monitoring_image" {
  description = "Prometheus to Cloud Monitoring image."
  type        = string
  default     = "gke.gcr.io/prometheus-engine/prometheus:v2.35.0-gmp.2-gke.0"
}

variable "replica_set" {
  description = "Replica set name."
  type        = string
  default     = null
}

variable "startup_image" {
  description = "Startup container image."
  type        = string
  default     = null
}

