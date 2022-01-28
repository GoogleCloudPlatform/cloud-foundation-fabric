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

variable "client_networks" {
  type = list(string)
  default = [
    "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/default"
  ]
}

variable "forwarders" {
  type    = map(string)
  default = {}
}

variable "peer_network" {
  type    = string
  default = null
}

variable "recordsets" {
  type = map(object({
    ttl     = number
    records = list(string)
  }))
  default = {
    "A localhost"                = { ttl = 300, records = ["127.0.0.1"] }
    "A local-host.test.example." = { ttl = 300, records = ["127.0.0.2"] }
    "CNAME *"                    = { ttl = 300, records = ["localhost.example.org."] }
    "A "                         = { ttl = 300, records = ["127.0.0.3"] }
  }
}

variable "type" {
  type    = string
  default = "private"
}
