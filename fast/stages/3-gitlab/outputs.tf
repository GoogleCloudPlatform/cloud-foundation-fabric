/**
 * Copyright 2024 Google LLC
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

locals {
  ssl_certs = {
#    "${var.gitlab_config.hostname}.key"    = local.gitlab_ssl_key,
#    "${var.gitlab_config.hostname}.ca.crt" = local.gitlab_ssl_ca_crt,
#    "${var.gitlab_config.hostname}.crt"    = local.gitlab_ssl_crt
  }
}

#output "postgresql_users" {
#  sensitive = true
#  value     = module.db.user_passwords
#}

output "ssh_to_bastion" {
  description = "gcloud command to ssh bastion host proxy."
  value       = nonsensitive("gcloud compute ssh ${module.squid-proxy-gitlab.squid_proxy_vm_name} --project ${module.gitlab_instance.project.project_id} --zone ${module.squid-proxy-gitlab.squid_proxy_vm.instance.zone} -- -L 3128:127.0.0.1:3128 -N -q -f")
}

output "ssh_to_gitlab" {
  description = "gcloud command to ssh gitlab instance."
  value       = nonsensitive("gcloud compute ssh ${module.gitlab_instance.instance.name} --project ${module.gitlab_instance.project.project_id} --zone  ${module.gitlab_instance.instance.zone} -- -L 8080:127.0.0.1:80 -L 2222:127.0.0.1:2222 -L 8443:127.0.0.1:443 -N -q -f")
}
