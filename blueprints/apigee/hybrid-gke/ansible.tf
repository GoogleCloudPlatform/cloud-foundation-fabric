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

# tfdoc:file:description Ansible generated files.

resource "local_file" "vars_file" {
  content = yamlencode({
    cluster          = module.cluster.name
    region           = var.region
    project_id       = module.project.project_id
    envgroups        = local.envgroups
    environments     = local.environments
    service_accounts = local.google_sas
    ingress_ip_name  = local.ingress_ip_name
  })
  filename        = "${path.module}/ansible/vars/vars.yaml"
  file_permission = "0644"
}

resource "local_file" "gssh_file" {
  content = templatefile("${path.module}/templates/gssh.sh.tpl", {
    project_id = module.project.project_id
    zone       = var.zone
  })
  filename        = "${path.module}/ansible/gssh.sh"
  file_permission = "0755"
}
