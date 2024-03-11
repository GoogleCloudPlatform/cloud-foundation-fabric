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

resource "google_vpc_access_connector" "connector" {
  count   = var.vpc_connector_create != null ? 1 : 0
  project = var.project_id
  name = (
    var.vpc_connector_create.name != null
    ? var.vpc_connector_create.name
    : var.name
  )
  region         = var.region
  ip_cidr_range  = var.vpc_connector_create.ip_cidr_range
  network        = var.vpc_connector_create.network
  machine_type   = var.vpc_connector_create.machine_type
  max_instances  = var.vpc_connector_create.instances.max
  max_throughput = var.vpc_connector_create.throughput.max
  min_instances  = var.vpc_connector_create.instances.min
  min_throughput = var.vpc_connector_create.throughput.min
  dynamic "subnet" {
    for_each = var.vpc_connector_create.subnet.name == null ? [] : [""]
    content {
      name       = var.vpc_connector_create.subnet.name
      project_id = var.vpc_connector_create.subnet.project_id
    }
  }
}

