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

variable "project_ids_full" {
  type        = map(string)
  description = "Project IDs (full)"
}

variable "environments" {
  type        = list(string)
  description = "List of environments"
}

variable "service_accounts" {
  type        = map(string)
  description = "Names of default Compute Engine service account"
}

variable "project_permissions" {
  type        = list(string)
  description = "List of permissions in the project"
}
