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


variable "config_directory" {
  description = "Paths to a folder where organization policy configs are stored in yaml format. Files suffix must be `.yaml`."
  type        = string
  default     = null
}

# TODO: convert to a proper data structure map(map(object({...}))) once tf1.3 is released and optional object keys are avaliable,
# for now it will cause multiple keys to be set to null for every policy definition
# https://github.com/hashicorp/terraform/releases/tag/v1.3.0-alpha20220622
variable "policies" {
  description = "Organization policies keyed by parent in format `projects/project-id`, `folders/1234567890` or `organizations/1234567890`."
  type        = any
  default     = {}
}
