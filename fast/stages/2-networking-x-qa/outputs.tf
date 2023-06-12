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

output "test-instances" {
  value = {
    nva-external = {
      ilb = module.hub-nva-ext-ilb-dmz.forwarding_rule_address
      vm  = module.hub-nva-external["a"].internal_ip
    }
    nva-external = {
      ilb = {
        for k, v in module.hub-nva-internal-ilb :
        k => v.forwarding_rule_address
      }
      vm = module.hub-nva-internal["a"].internal_ip
    }
    test-dev-0       = module.test-vm-dev-0.internal_ip
    test-dmz-0       = module.test-vm-dmz-0.internal_ip
    test-inside-0    = module.test-vm-inside-0.internal_ip
    test-prod-0      = module.test-vm-prod-0.internal_ip
    test-untrusted-0 = module.test-vm-untrusted-0.internal_ip
  }
}
