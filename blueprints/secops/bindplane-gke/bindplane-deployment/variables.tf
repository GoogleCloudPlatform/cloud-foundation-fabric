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

variable "bindplane_secrets" {
  description = "Bindplane configuration."
  type = object({
    license         = string
    user            = optional(string, "admin")
    password        = optional(string, null)
    sessions_secret = string
  })
}

variable "bindplane_tls" {
  description = "Bindplane TLS certificates."
  type = object({
    cer = string
    key = string
  })
}
