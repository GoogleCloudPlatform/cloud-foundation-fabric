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

locals {
  gcs_storage_class = (
    length(split("-", local.locations.gcs)) < 2
    ? "MULTI_REGIONAL"
    : "REGIONAL"
  )
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
    logging = coalesce(try(local.checklist.location, null), var.locations.logging)
    pubsub  = var.locations.pubsub
  }
  # naming: environment used in most resource names
  prefix = join("-", compact([var.prefix, "prod"]))
}
