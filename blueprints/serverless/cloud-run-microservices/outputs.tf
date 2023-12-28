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
  value = (
    local.two_projects == true ? "http://${var.custom_domain}" : "none"
  )
}

output "default_URLs" {
  description = "Cloud Run services default URLs."
  value = {
    service_a = module.cloud-run-svc-a.service.uri
    service_b = module.cloud-run-svc-b.service.uri
  }
}

output "load_balancer_ip" {
  description = "Load Balancer IP address."
  value = (
    local.two_projects == true ? module.int-alb[0].address : "none"
  )
}
