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

variable "enable_autopilot" {
  default = false
}

variable "addons" {
  default = {
    cloudrun_config            = false
    dns_cache_config           = false
    horizontal_pod_autoscaling = true
    http_load_balancing        = true
    istio_config = {
      enabled = false
      tls     = false
    }
    network_policy_config                 = false
    gce_persistent_disk_csi_driver_config = false
    gcp_filestore_csi_driver_config       = false
    config_connector_config               = false
    kalm_config                           = false
    gke_backup_agent_config               = false
  }
}
