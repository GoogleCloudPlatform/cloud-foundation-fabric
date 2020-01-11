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

variable "sinks" {
  description = "Logging sinks that will be created, options default to true except for unique_writer_identity."
  type = list(object({
    # organizations/nnn, billing_accounts/nnn, folders/nnn, projects/nnn
    name        = string
    resource    = string
    filter      = string
    destination = string
    options = object({
      bigquery_partitioned_tables = bool
      include_children            = bool
      unique_writer_identity      = bool
    })
  }))
  default = []
}
