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

resource "google_notebooks_runtime" "runtime" {
  for_each = var.notebooks
  name     = each.key

  project  = module.project.project_id
  location = var.notebooks[each.key].region
  access_config {
    access_type   = "SINGLE_USER"
    runtime_owner = var.notebooks[each.key].owner
  }
  software_config {
    enable_health_monitoring = true
    idle_shutdown            = var.notebooks[each.key].idle_shutdown
    idle_shutdown_timeout    = 1800
  }
  virtual_machine {
    virtual_machine_config {
      machine_type     = "n1-standard-4"
      network          = local.vpc
      subnet           = local.subnet
      internal_ip_only = var.notebooks[each.key].internal_ip_only
      dynamic "encryption_config" {
        for_each = try(local.service_encryption_keys.compute, null) == null ? [] : [1]
        content {
          kms_key = local.service_encryption_keys.compute
        }
      }
      metadata = {
        notebook-disable-nbconvert = "false"
        notebook-disable-downloads = "false"
        notebook-disable-terminal  = "false"
        #notebook-disable-root      = "true"
        #notebook-upgrade-schedule  = "48 4 * * MON"
      }
      data_disk {
        initialize_params {
          disk_size_gb = "100"
          disk_type    = "PD_STANDARD"
        }
      }
    }
  }
}

