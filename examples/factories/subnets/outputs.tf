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

output "subnet" {
  description = "Generated subnets"
  value = {
    for k, v in google_compute_subnetwork.default :
    k => {
      id        = v.id
      network   = v.network
      project   = v.project
      range     = v.ip_cidr_range
      region    = v.region
      self_link = v.self_link
    }
  }
}
