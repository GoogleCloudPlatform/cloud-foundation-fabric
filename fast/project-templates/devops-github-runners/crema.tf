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

module "crema-autoscaler" {
  source              = "../../../modules/cloud-run-v2"
  project_id          = module.project.project_id
  region              = local.location
  name                = "${local.prefix}${var.crema_config.service_name}"
  type                = "SERVICE"
  deletion_protection = var.crema_config.deletion_protection
  service_account_config = {
    create = false
    email  = local.crema_sa_email
  }
  service_config = {
    ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
    scaling = {
      min_instance_count = 1
      max_instance_count = 1
    }
  }
  containers = {
    crema = {
      image = var.crema_config.image
      resources = {
        cpu_idle = false
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
      env = {
        CREMA_CONFIG          = google_parameter_manager_regional_parameter_version.crema_config.id
        ENABLE_CLOUD_LOGGING  = "True"
        LOG_FORMAT            = "json"
        OUTPUT_SCALER_METRICS = "True"
      }
    }
  }
  depends_on = [module.worker-pool]
}
