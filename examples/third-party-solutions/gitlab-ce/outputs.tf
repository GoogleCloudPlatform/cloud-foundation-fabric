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

locals {
  migs = {
    for k, v in google_compute_instance_group_manager.default : k => v.name
  }
}

output "commands" {
  value = {
    for k, v in local.zones : v => {
      create = join(" \\\n  ", [
        "gcloud compute instance-groups managed create-instance ${local.migs[k]}",
        "--project ${var.project_id}",
        "--instance ${var.prefix}-${k}",
        "--zone ${v}",
        "--stateful-disk device-name=data,auto-delete=never,source=${google_compute_region_disk.data.id}",
        ]
      )
      delete = join(" \\\n  ", [
        "gcloud compute instance-groups managed delete-instances ${local.migs[k]}",
        "--project ${var.project_id}",
        "--instances ${var.prefix}-${k}",
        "--zone ${v}"
      ])
    }
  }
}
