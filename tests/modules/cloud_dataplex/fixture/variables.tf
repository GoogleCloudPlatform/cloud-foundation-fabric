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


variable "asset_name" {
  description = "Asset of the Dataplex Asset."
  type        = string
  default     = "test_gcs"
}

variable "bucket_name" {
  description = "Bucket name of the Dataplex asset."
  type        = string
  default     = "test_gcs"
}

variable "name" {
  description = "Name of dataplex lake instance."
  type        = string
  default     = "terraform-lake"
}

variable "prefix" {
  description = "Optional prefix used to generate instance names."
  type        = string
  default     = "test"
}

variable "project_id" {
  description = "The ID of the project where this instances will be created."
  type        = string
  default     = "myproject"
}

variable "region" {
  description = "Region of the Dataplax Lake."
  type        = string
  default     = "europe-west2"
}

variable "zone_name" {
  description = "Zone of the Dataplex Zone."
  type        = string
  default     = "zone"
}
