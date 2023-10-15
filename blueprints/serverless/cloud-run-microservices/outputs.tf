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

output "custom_domain" {
  description = "Custom domain for the Application Load Balancer."
  value       = var.prj_svc1_id != null ? "http://${var.custom_domain}" : "none"
}

output "default_URL_client" {
  description = "Client Cloud Run service default URL."
  value       = module.cloud_run_client.service.status[0].url
}

output "default_URL_server" {
  description = "Server Cloud Run service default URL."
  value       = module.cloud_run_server.service.status[0].url
}

output "load_balancer_ip" {
  description = "Load Balancer IP address."
  value       = var.prj_svc1_id != null ? module.int-alb[0].address : "none"
}
