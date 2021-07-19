/**
 * Copyright 2021 Google LLC
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

output "addresses" {
  description = "IP addresses."
  value = {
    gw        = module.gw.internal_ips
    ilb-left  = module.ilb-left.forwarding_rule_address
    ilb-right = module.ilb-right.forwarding_rule_address
    vm-left   = module.vm-left.internal_ips
    vm-right  = module.vm-right.internal_ips
  }
}

output "backend_health_left" {
  description = "Command-line health status for left ILB backends."
  value       = <<-EOT
    gcloud compute backend-services get-health ${local.prefix}ilb-left \
      --region ${var.region} \
      --flatten status.healthStatus \
      --format "value(status.healthStatus.ipAddress, status.healthStatus.healthState)"
  EOT
}

output "backend_health_right" {
  description = "Command-line health status for right ILB backends."
  value       = <<-EOT
    gcloud compute backend-services get-health ${local.prefix}ilb-right \
      --region ${var.region} \
      --flatten status.healthStatus \
      --format "value(status.healthStatus.ipAddress, status.healthStatus.healthState)"
  EOT
}

output "ssh_gw" {
  description = "Command-line login to gateway VMs."
  value = [
    for name, instance in module.gw.instances :
    "gcloud compute ssh ${instance.name} --project ${var.project_id} --zone ${instance.zone}"
  ]
}

output "ssh_vm_left" {
  description = "Command-line login to left VMs."
  value = [
    for name, instance in module.vm-left.instances :
    "gcloud compute ssh ${instance.name} --project ${var.project_id} --zone ${instance.zone}"
  ]
}

output "ssh_vm_right" {
  description = "Command-line login to right VMs."
  value = [
    for name, instance in module.vm-right.instances :
    "gcloud compute ssh ${instance.name} --project ${var.project_id} --zone ${instance.zone}"
  ]
}
