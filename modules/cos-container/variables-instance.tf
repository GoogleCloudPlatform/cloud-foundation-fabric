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

variable "test_instance" {
  description = "Test/development instance attributes, leave null to skip creation."
  type = object({
    project_id = string
    zone       = string
    name       = string
    type       = string
    tags       = list(string)
    metadata   = map(string)
    network    = string
    subnetwork = string
    disks = list(object({
      device_name = string
      mode        = string
      source      = string
    }))
  })
  default = null
}
