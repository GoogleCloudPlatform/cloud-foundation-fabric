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

output "egress_public_ip" {
  description = "Public IP address of Looker instance for egress."
  value       = google_looker_instance.looker.egress_public_ip
}

output "egress_service_attachments" {
  description = "Egress service attachment connection statuses and configurations."
  value       = try(google_looker_instance.looker.psc_config[0].service_attachments, [])
}

output "id" {
  description = "Fully qualified primary instance id."
  value       = google_looker_instance.looker.id
}

output "ingress_private_ip" {
  description = "Private IP address of Looker instance for ingress."
  value       = google_looker_instance.looker.ingress_private_ip
}

output "ingress_public_ip" {
  description = "Public IP address of Looker instance for ingress."
  value       = google_looker_instance.looker.ingress_public_ip
}

output "instance" {
  description = "Looker Core instance resource."
  value       = google_looker_instance.looker
  sensitive   = true
}

output "instance_id" {
  description = "Looker Core instance id."
  value       = google_looker_instance.looker.id
  sensitive   = true
}

output "instance_name" {
  description = "Name of the looker instance."
  value       = google_looker_instance.looker.name
}

output "looker_uri" {
  description = "Looker core URI."
  value       = google_looker_instance.looker.looker_uri
}

output "looker_service_attachment" {
  description = "Service attachment URI for the Looker instance."
  value       = try(google_looker_instance.looker.psc_config[0].looker_service_attachment_uri, null)
}

output "looker_version" {
  description = "Looker core version."
  value       = google_looker_instance.looker.looker_version
}
