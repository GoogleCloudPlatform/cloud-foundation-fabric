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

output "onprem-instance" {
  description = "Onprem instance details."
  value = {
    external_ip = module.vm-onprem.external_ips.0
    internal_ip = module.vm-onprem.internal_ips.0
    name        = module.vm-onprem.names.0
  }
}

output "test-instance1" {
  description = "Test instance details."
  value = join(" ", [
    module.vm-test1.names[0],
    module.vm-test1.internal_ips[0]
  ])
}
output "test-instance2" {
  description = "Test instance details."
  value = join(" ", [
    module.vm-test2.names[0],
    module.vm-test2.internal_ips[0]
  ])
}
