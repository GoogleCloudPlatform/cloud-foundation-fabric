/**
 * Copyright 2024 Google LLC
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

locals {
  default_environment = [
    for k, v in local.environments : v if v.is_default
  ][0]
  environments = {
    for k, v in var.environments : k => {
      is_default = v.is_default
      key        = k
      name       = v.name
      short_name = v.short_name != null ? v.short_name : k
      tag_name   = v.tag_name != null ? v.tag_name : lower(v.name)
    }
  }
  principals = {
    for k, v in var.groups : k => (
      can(regex("^[a-zA-Z]+:", v))
      ? v
      : "group:${v}@${var.organization.domain}"
    )
  }
  locations = {
    bq      = var.locations.bq
    gcs     = var.locations.gcs
    logging = var.locations.logging
    pubsub  = var.locations.pubsub
  }
}
