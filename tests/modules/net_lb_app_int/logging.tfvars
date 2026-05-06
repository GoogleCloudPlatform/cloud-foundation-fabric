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

backend_service_configs = {
  logging-enabled = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
    }]
    log_config = {
      enable      = true
      sample_rate = 0.5
    }
  }
  logging-disabled = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
    }]
    log_config = {
      enable = false
    }
  }
  logging-advanced = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
    }]
    log_config = {
      enable          = true
      sample_rate     = 0.8
      optional_mode   = "CUSTOM"
      optional_fields = ["orca_load_report", "tls.protocol"]
    }
  }
}
