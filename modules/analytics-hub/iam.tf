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
  listing_iam = flatten([
    for listing_id, listing_configs in local.factory_listings : [
      for role, members in coalesce(listing_configs.iam, tomap({})) : {
        listing_id = listing_id
        role       = role
        members    = members
      }
    ]
  ])
}

resource "google_bigquery_analytics_hub_data_exchange_iam_binding" "exchange_iam_bindings" {
  for_each         = var.iam
  project          = google_bigquery_analytics_hub_data_exchange.data_exchange.project
  location         = google_bigquery_analytics_hub_data_exchange.data_exchange.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.data_exchange.data_exchange_id
  role             = each.key
  members          = each.value
}

resource "google_bigquery_analytics_hub_listing_iam_binding" "listing_iam_bindings" {
  for_each = {
    for index, listing_iam in local.listing_iam :
    "${listing_iam.listing_id}-${listing_iam.role}" => listing_iam
  }
  project          = google_bigquery_analytics_hub_data_exchange.data_exchange.project
  location         = google_bigquery_analytics_hub_data_exchange.data_exchange.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.data_exchange.data_exchange_id
  listing_id       = each.value.listing_id
  role             = each.value.role
  members          = each.value.members
  depends_on       = [google_bigquery_analytics_hub_listing.listing]
}
