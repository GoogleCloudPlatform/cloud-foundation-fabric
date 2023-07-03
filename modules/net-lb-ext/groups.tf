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

# tfdoc:file:description Optional instance group resources.

resource "google_compute_instance_group" "default" {
  for_each    = var.group_configs
  project     = var.project_id
  zone        = each.value.zone
  name        = "${var.name}-${each.key}"
  description = var.description
  instances   = each.value.instances

  dynamic "named_port" {
    for_each = each.value.named_ports
    content {
      name = named_port.key
      port = named_port.value
    }
  }
}
