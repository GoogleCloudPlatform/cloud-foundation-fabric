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

module "test" {
  source                    = "../../../../modules/naming-convention"
  prefix = var.prefix
  suffix = var.suffix
  use_resource_prefixes = var.use_resource_prefixes
  environment = "dev"
  team = "cloud"
  resources = {
    bucket = ["tf-org", "tf-sec", "tf-log"]
    project = ["tf", "sec", "log"]
  }
  labels = {
    project = {
      tf = {scope = "global"}
    }
  }
}

output "labels" {
  value = module.test.labels
}

output "names" {
  value = module.test.names
}

variable "prefix" {
  type    = string
  default = null
}

variable "suffix" {
  type    = string
  default = null
}

variable "use_resource_prefixes" {
  type    = bool
  default = false
}
