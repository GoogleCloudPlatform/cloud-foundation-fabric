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

variable "group_iam" {
  type    = any
  default = {}
}

variable "iam" {
  type     = any
  default  = {}
  nullable = false
}

variable "iam_additive" {
  type     = any
  default  = {}
  nullable = false
}

variable "iam_additive_members" {
  type    = any
  default = {}
}

variable "name" {
  description = "Repository name."
  type        = string
  default     = "test"
}

variable "project_id" {
  description = "Project used for resources."
  type        = string
  default     = "test"
}

variable "triggers" {
  type    = any
  default = null
}

module "test" {
  source               = "../../../../modules/source-repository"
  project_id           = var.project_id
  name                 = var.name
  group_iam            = var.group_iam
  iam                  = var.iam
  iam_additive         = var.iam_additive
  iam_additive_members = var.iam_additive_members
  triggers             = var.triggers
}
