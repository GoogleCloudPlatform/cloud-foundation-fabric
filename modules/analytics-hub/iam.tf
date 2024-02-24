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
  _exchange_iam_principal_roles = distinct(flatten(values(var.iam_by_principals)))
  _exchange_iam_principals = {
    for r in local._exchange_iam_principal_roles : r => [
      for k, v in var.iam_by_principals :
      k if try(index(v, r), null) != null
    ]
  }
  _exchange_iam_bindings = {
    for key, iam_bindings in var.iam_bindings :
    iam_bindings.role => iam_bindings.members
  }
  exchange_iam = {
    for role in distinct(concat(keys(var.iam), keys(local._exchange_iam_principals), keys(local._exchange_iam_bindings))) :
    role => concat(
      try(var.iam[role], []),
      try(local._exchange_iam_principals[role], []),
      try(local._exchange_iam_bindings[role], []),
    )
  }
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
  for_each         = local.exchange_iam
  project          = google_bigquery_analytics_hub_data_exchange.data_exchange.project
  location         = google_bigquery_analytics_hub_data_exchange.data_exchange.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.data_exchange.data_exchange_id
  role             = each.key
  members          = each.value
}

resource "google_bigquery_analytics_hub_data_exchange_iam_member" "exchange_iam_members" {
  for_each         = var.iam_bindings_additive
  project          = google_bigquery_analytics_hub_data_exchange.data_exchange.project
  location         = google_bigquery_analytics_hub_data_exchange.data_exchange.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.data_exchange.data_exchange_id
  role             = each.value.role
  member           = each.value.member
}

resource "google_bigquery_analytics_hub_listing_iam_binding" "listing_iam_bindings" {
  for_each = {
    for index, listing_iam in local.listing_iam :
    "${listing_iam.listing_id}-${listing_iam.role}" => listing_iam
  }
  project          = google_bigquery_analytics_hub_data_exchange.data_exchange.project
  location         = google_bigquery_analytics_hub_data_exchange.data_exchange.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.data_exchange.data_exchange_id
  listing_id       = google_bigquery_analytics_hub_listing.listing[each.value.listing_id].id
  role             = each.value.role
  members          = each.value.members
}
