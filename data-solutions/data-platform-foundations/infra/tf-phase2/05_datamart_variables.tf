/**
 * Copyright 2020 Google LLC
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

###############################################################################
#                                Datamart                                     #
###############################################################################
variable "datamart_project_id" {
  description = "datamart project ID."
  type        = string
}

variable "datamart_service_account" {
  description = "datamart service accounts list."
  type        = string
  default     = "sa-datamart"
}

variable "datamart_bq_datasets" {
  description = "Datamart Bigquery datasets"
  type        = map(any)
  default = {
    bq_datamart_dataset = {
      id       = "bq_datamart_dataset"
      location = "EU",
    }
  }
}
