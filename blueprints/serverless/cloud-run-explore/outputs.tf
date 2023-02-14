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

# Custom domain for the Load Balancer. I'd prefer getting the value from the
# SSL certificate but it is not exported as output
output "custom_domain" {
  description = "Custom domain for the Load Balancer."
  value       = local.gclb_create ? var.custom_domain : "none"
}

output "default_URL" {
  description = "Cloud Run service default URL."
  value       = module.cloud_run.service.status[0].url
}

output "load_balancer_ip" {
  description = "LB IP that forwards to Cloud Run service."
  value       = local.gclb_create ? module.glb[0].address : "none"
}
