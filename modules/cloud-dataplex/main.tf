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
        resource_name          = asset_data.resource_name
        resource_project       = coalesce(asset_data.resource_project, var.project_id)
        cron_schedule          = asset_data.discovery_spec_enabled ? asset_data.cron_schedule : null
        discovery_spec_enabled = asset_data.discovery_spec_enabled
        resource_spec_type     = asset_data.resource_spec_type
      }
    ]
  ])

  zone_iam = flatten([
    for zone, zone_details in var.zones : [
      for role, members in zone_details.iam : {
        "zone"    = zone
        "role"    = role
        "members" = members
      }
    ] if zone_details.iam != null
  ])

  resource_type_mapping = {
    "STORAGE_BUCKET" : "buckets",
    "BIGQUERY_DATASET" : "datasets"
  }
}

resource "google_dataplex_lake" "lake" {
  name     = "${local.prefix}${var.name}"
  location = var.region
  provider = google-beta
  project  = var.project_id
}

resource "google_dataplex_lake_iam_binding" "binding" {
  for_each = var.iam
  project  = var.project_id
  location = var.region
  lake     = google_dataplex_lake.lake.name
  role     = each.key
  members  = each.value
}

resource "google_dataplex_zone" "zone" {
  for_each = var.zones
  provider = google-beta
  project  = var.project_id
  name     = each.key
  location = var.region
  lake     = google_dataplex_lake.lake.name
  type     = each.value.type

  discovery_spec {
    enabled = each.value.discovery
  }

  resource_spec {
    location_type = var.location_type
  }
}

resource "google_dataplex_zone_iam_binding" "binding" {
  for_each = {
    for zone_role in local.zone_iam : "${zone_role.zone}-${zone_role.role}" => zone_role
  }
  project       = var.project_id
  location      = var.region
  lake          = google_dataplex_lake.lake.name
  dataplex_zone = google_dataplex_zone.zone[each.value.zone].name
  role          = each.value.role
  members       = each.value.members
}

resource "google_dataplex_asset" "asset" {
  for_each = {
    for tm in local.zone_assets : "${tm.zone_name}-${tm.asset_name}" => tm
  }
  name     = each.value.asset_name
  location = var.region
  provider = google-beta

  lake          = google_dataplex_lake.lake.name
  dataplex_zone = google_dataplex_zone.zone[each.value.zone_name].name

  discovery_spec {
    enabled  = each.value.discovery_spec_enabled
    schedule = each.value.cron_schedule
  }

  resource_spec {
    name = format("projects/%s/%s/%s",
      each.value.resource_project,
      local.resource_type_mapping[each.value.resource_spec_type],
      each.value.resource_name
    )
    type = each.value.resource_spec_type
  }
  project = var.project_id
}
