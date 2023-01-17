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

variable "enable_addons" {
  type = any
  default = {
    horizontal_pod_autoscaling = true
    http_load_balancing        = true
  }
}

variable "enable_features" {
  type = any
  default = {
    workload_identity = true
  }
}

variable "monitoring_config" {
  type = any
  default = {
    managed_prometheus = true
  }
}

variable "tags" {
  description = "Network tags applied to nodes."
  type        = list(string)
  default     = null
}
