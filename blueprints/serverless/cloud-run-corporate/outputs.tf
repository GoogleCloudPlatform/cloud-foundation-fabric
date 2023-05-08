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

output "default_URL_cart" {
  description = "Cloud Run service 'cart' default URL."
  value = (var.prj_svc1_id != null ?
  module.cloud_run_cart[0].service.status[0].url : "none")
}

output "default_URL_checkout" {
  description = "Cloud Run service 'checkout' default URL."
  value = (var.prj_svc1_id != null ?
  module.cloud_run_checkout[0].service.status[0].url : "none")
}

output "default_URL_hello" {
  description = "Cloud Run service 'hello' default URL."
  value       = module.cloud_run_hello.service.status[0].url
}

output "load_balancer_ip" {
  description = "Load Balancer IP address."
  value       = var.custom_domain != null ? module.ilb-l7[0].address : "none"
}
