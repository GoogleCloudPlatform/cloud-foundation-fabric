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

output "instances" {
  description = "Instances details."
  value = {
    addresses = {
      for k, v in module.instances : k => v.internal_ip
    }
    commands = {
      for k, v in module.instances : k => (
        "gssh ${nonsensitive(v.instance.name)} --project ${var.project_id} --zone ${nonsensitive(v.instance.zone)}"
      )
    }
    groups = {
      for k, v in module.instances : k => v.group.id
    }
  }
}

output "lb" {
  description = "Load balancer details."
  value = {
    addresses = module.load-balancer.addresses
  }
}
