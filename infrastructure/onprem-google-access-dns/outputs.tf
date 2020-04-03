/**
 * Copyright 2020 Google LLC
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
  value = join(" ", [
    module.on-prem.instance_name,
    module.on-prem.internal_address,
    module.on-prem.external_address
  ])
}

output "test-instance" {
  description = "Test instance details."
  value = join(" ", [
    module.vm-test.names[0],
    module.vm-test.internal_ips[0]
  ])
}

output "foo" {
  value = {
    dns  = data.google_netblock_ip_ranges.dns-forwarders.cidr_blocks_ipv4
    apis = data.google_netblock_ip_ranges.private-googleapis.cidr_blocks_ipv4
  }
}
