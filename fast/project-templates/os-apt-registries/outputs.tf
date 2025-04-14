/**
 * Copyright 2025 Google LLC
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
  format = "deb ar+https://%s-apt.pkg.dev/remote/%s/%s %s main"
}

# europe-west8-apt.pkg.dev/ldj-prod-os-apt-0/apt-remote-bookworm

output "apt_configs" {
  description = "APT configurations for remote registries."
  value = {
    for k, v in module.registries : v.name => format(
      local.format, var.location, var.project_id,
      v.name, local.apt_remote_registries[k].name
    )
  }
}

output "vpcsc_command" {
  description = "Command to allow egress to remotes from inside a perimeter."
  value = (
    "gcloud artifacts vpcsc-config allow --project=${var.project_id} --location=${var.location}"
  )
}
