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

output "docker_registry" {
  description = "Docker registry URL."
  value       = module.registry.url
}

output "secret" {
  description = "Azure token secret."
  value       = module.secret.secrets[var.name].id
}

output "ssh_command" {
  description = "Command to SSH to the agent instance."
  value = nonsensitive(try(
    "gcloud compute ssh ${module.instance[0].instance.name} --zone ${module.instance[0].instance.zone} --project ${var.project_id}",
    null
  ))
}

output "vpcsc_command" {
  description = "Command to allow egress to remotes from inside a perimeter."
  value = (
    "gcloud artifacts vpcsc-config allow --project=${var.project_id} --location=${var.location}"
  )
}
