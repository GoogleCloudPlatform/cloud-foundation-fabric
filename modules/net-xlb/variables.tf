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

variable "name" {
  description = "Load balancer name."
  type        = string
}

variable "project_id" {
  description = "Project id."
  type        = string
}

variable "health_check_config_default" {
  description = "Auto-created helth check default configuration."
  type        = any
  default     = {}
}

# type    = string      # http https tcp ssl http2
# check   = map(any)    # health check - check block attributes
# logging = bool
variable "health_checks_configs" {
  description = "Custom health checks configurations."
  type        = any
  default     = {}
}

variable "backends_configs" {
  #   type         = string      # bucket, group
  #   config       = any         # optional additional params for each backend config
  #   logging      = bool
  #   health_check = map(string) # optional health_check, otherwise health_check_config_default will be used
  #   backend      = [
  #     {
  #     }
  #   ]
  description = "The list of backends."
  type        = any
}

variable "url_map_configs" {
  description = "The url-map configuration."
  type        = any
  default     = {}
}

variable "ssl_certificate_configs" {
  description = "The SSL certificate configurations. Look at ssl_certificates.tf for defaults."
  type        = any
  default     = {}
}

variable "global_forwarding_rule_configs" {
  description = "Global forwarding rule configurations."
  type        = any
  default     = {}
}

variable "https" {
  description = "Whether to enable HTTPS."
  type        = bool
  default     = false
}

variable "reserve_ip_address" {
  description = "Whether to reserve a static global IP address."
  type        = bool
  default     = false
}
