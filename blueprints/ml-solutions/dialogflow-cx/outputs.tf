# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Output variables.

output "cx_agent_id" {
  description = "Dialoglfow CX agent id."
  value       = google_dialogflow_cx_webhook.webhook.id
}

output "project" {
  description = "GCP Project information."
  value = {
    project_number = module.project.number
    project_id     = module.project.project_id
  }
}

output "webhook" {
  description = "Webhook information."
  value = {
    ilb_address               = module.ilb-l7.address
    image                     = try(module.cloud_run.service.template[0].spec[0].containers[0].image, null)
    host                      = try(module.cloud_run.service.status.0.url, null)
    service_directory_service = google_service_directory_service.service.name
  }
}
