/**
 * Copyright 2022 Google LLC
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

# optionally generate files for subsequent stages

resource "local_file" "dev_sec_kms" {
  for_each = var.outputs_location == null ? {} : { 1 = 1 }
  filename = "${var.outputs_location}/yamls/02-security-kms-dev-keys.yaml"
  content = yamlencode({
    for k, m in module.dev-sec-kms : k => m.key_ids
  })
}

resource "local_file" "prod_sec_kms" {
  for_each = var.outputs_location == null ? {} : { 1 = 1 }
  filename = "${var.outputs_location}/yamls/02-security-kms-prod-keys.yaml"
  content = yamlencode({
    for k, m in module.prod-sec-kms : k => m.key_ids
  })
}

# outputs

output "stage_perimeter_projects" {
  description = "Security project numbers. They can be added to perimeter resources."
  value = {
    dev  = ["projects/${module.dev-sec-project.number}"]
    prod = ["projects/${module.prod-sec-project.number}"]
  }
}
