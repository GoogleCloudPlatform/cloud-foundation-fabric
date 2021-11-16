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

variable "projects" {
  description = "Projects"
  type        = any
}

variable "recommendations_topic" {
  description = "Recommendations topic"
  type        = string
  default     = ""
}

variable "scheduler_cron" {
  description = "Cloud Scheduler cron"
  type        = string
  default     = "0 4 * * *"
}

variable "scheduler_timezone" {
  description = "Cloud Scheduler timezone"
  type        = string
  default     = "Etc/UTC"
}

variable "scheduler_region" {
  description = "Cloud Scheduler region"
  type        = string
  default     = "europe-west1"
}

variable "scheduler_project" {
  description = "Scheduler project"
  type        = string
}
