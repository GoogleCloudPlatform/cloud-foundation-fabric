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

locals {
  prefix = var.prefix == null ? "" : "${var.prefix}-"
}

resource "google_dataplex_lake" "basic_lake" {
  name     = "${local.prefix}${var.name}"
  location = var.region
  provider = google-beta
  project  = var.project_id
}

resource "google_dataplex_zone" "basic_zone" {
  name     = var.zone_name
  location = var.region
  provider = google-beta
  lake     = google_dataplex_lake.basic_lake.name
  type     = var.zone_type

  discovery_spec {
    enabled = var.enabled
  }

  resource_spec {
    location_type = var.location_type
  }

  project = var.project_id
}

resource "google_dataplex_asset" "primary" {
  name     = var.asset_name
  location = var.region
  provider = google-beta

  lake          = google_dataplex_lake.basic_lake.name
  dataplex_zone = google_dataplex_zone.basic_zone.name

  discovery_spec {
    enabled  = var.discovery_spec_enabled
    schedule = var.cron_schedule
  }

  resource_spec {
    name = "projects/${var.project_id}/buckets/${var.bucket_name}"
    type = var.resource_spec_type
  }
  project = var.project_id
}
