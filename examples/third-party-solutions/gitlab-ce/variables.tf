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

variable "gce_config" {
  type = object({
    disk_size    = number
    disk_type    = string
    machine_type = string
    zones        = list(string)
  })
  default = {
    disk_size    = 20
    disk_type    = "pd-balanced"
    machine_type = "e2-standard-2"
    zones        = ["b", "c"]
  }
  nullable = false
}

variable "gitlab_config" {
  type = object({
    env   = map(string)
    image = string
  })
  default = {
    env = {
      foo = "bar"
      bar = "baz"
    }
    image = "gitlab/gitlab-ce:latest"
  }
  nullable = false
}

variable "prefix" {
  type    = string
  default = "mig-test"
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "subnet_self_link" {
  type = string
}

variable "tags" {
  type    = list(string)
  default = ["gitlab", "http-server", "https-server", "ssh"]
}
