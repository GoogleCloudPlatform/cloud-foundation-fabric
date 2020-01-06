/**
 * Copyright 2020 Google LLC
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

output "instances" {
  description = "Instance resources."
  value       = module.cos-coredns.instances
}

output "names" {
  description = "Instance names."
  value       = module.cos-coredns.names
}

output "self_links" {
  description = "Instance self links."
  value       = module.cos-coredns.self_links
}

output "internal_ips" {
  description = "Instance main interface internal IP addresses."
  value       = module.cos-coredns.internal_ips
}

output "external_ips" {
  description = "Instance main interface external IP addresses."
  value       = module.cos-coredns.external_ips
}

output "template" {
  description = "Template resource."
  value       = module.cos-coredns.template
}

output "template_name" {
  description = "Template name."
  value       = module.cos-coredns.template_name
}
