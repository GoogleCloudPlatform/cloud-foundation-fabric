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
  zone_assets = flatten([
    for zone, zones_info in var.zones : [
      for asset, asset_data in zones_info.assets : {
        zone_name              = zone
        asset_name             = asset
        bucket_name            = asset_data.bucket_name
        cron_schedule          = asset_data.cron_schedule
        discovery_spec_enabled = asset_data.discovery_spec_enabled
        resource_spec_type     = asset_data.resource_spec_type
      }
    ]
  ])
}

resource "google_dataplex_lake" "basic_lake" {
  name     = "${local.prefix}${var.name}"
  location = var.region
  provider = google-beta
  project  = var.project_id
}

resource "google_dataplex_zone" "basic_zone" {
  for_each = var.zones
  name     = each.key
  location = var.region
  provider = google-beta
  lake     = google_dataplex_lake.basic_lake.name
  type     = each.value.type

  discovery_spec {
    enabled = each.value.discovery
  }

  resource_spec {
    location_type = var.location_type
  }

  project = var.project_id
}

resource "google_dataplex_asset" "primary" {
  for_each = {
    for tm in local.zone_assets : "${tm.zone_name}-${tm.asset_name}" => tm
  }
  name     = each.value.asset_name
  location = var.region
  provider = google-beta

  lake          = google_dataplex_lake.basic_lake.name
  dataplex_zone = google_dataplex_zone.basic_zone[each.value.zone_name].name

  discovery_spec {
    enabled  = each.value.discovery_spec_enabled
    schedule = each.value.cron_schedule
  }

  resource_spec {
    name = "projects/${var.project_id}/buckets/${each.value.bucket_name}"
    type = each.value.resource_spec_type
  }
  project = var.project_id
}
