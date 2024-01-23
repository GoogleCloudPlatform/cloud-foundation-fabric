/**
 * Copyright 2023 Google LLC
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

variable "dataform_remote_repository_branch" {
  description = "Default branch, default is \"main\"."
  type        = string
  default     = "main"
}
variable "dataform_remote_repository_token" {
  description = "the token value to be stored in a secret. Attention: this should not be stored on e.g. Github."
  type        = string
  default     = ""
}

variable "dataform_remote_repository_url" {
  description = "URL of the remote repository."
  type        = string
  default     = ""
}
variable "dataform_repository_name" {
  description = "The dataform repositories name."
  type        = string
}
variable "dataform_secret_name" {
  description = "Name of the secret the token to the remote repository is stored."
  type        = string
  default     = ""
}
variable "dataform_service_account" {
  description = "Service account to be used to run workflow executions, if not the default dataform service account."
  type        = string
  default     = ""
}
variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}
variable "project_id" {
  description = "Id of the project where repository will be created."
  type        = string
}
variable "region" {
  description = "Repository region."
  type        = string
  default     = "europe-west3"
}

