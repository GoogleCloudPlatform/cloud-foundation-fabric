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

resource "google_cloudbuild_worker_pool" "default" {
  project  = local.build_project_id
  name     = "${local.prefix}${var.name}"
  location = local.location
  worker_config {
    disk_size_gb   = var.build_pool_config.disk_size_gb
    machine_type   = var.build_pool_config.machine_type
    no_external_ip = true
  }
  network_config {
    peered_network          = local.peered_network
    peered_network_ip_range = var.build_pool_config.psa_range_size
  }
}
