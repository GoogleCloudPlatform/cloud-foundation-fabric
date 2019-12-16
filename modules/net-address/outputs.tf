/**
 * Copyright 2019 Google LLC
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

output "external_addresses" {
  value = {
    for address in google_compute_address.external :
    address.name => {
      address   = address.address
      self_link = address.self_link
      users     = address.users
    }
  }
}

output "global_addresses" {
  value = {
    for address in google_compute_global_address.global :
    address.name => {
      address   = address.address
      self_link = address.self_link
      status    = address.status
    }
  }
}

output "internal_addresses" {
  value = {
    for address in google_compute_address.internal :
    address.name => {
      address   = address.address
      self_link = address.self_link
      users     = address.users
    }
  }
}
