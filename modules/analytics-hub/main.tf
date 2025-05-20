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
  prefix                 = var.prefix == null || var.prefix == "" ? "" : "${var.prefix}_"
  _factory_listings_path = pathexpand(coalesce(var.factories_config.listings, "-"))
  _factory_listings = {
    for f in try(fileset(local._factory_listings_path, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local._factory_listings_path}/${f}")
    )
  }
  factory_listings = merge(local._factory_listings, var.listings)
}

resource "google_bigquery_analytics_hub_data_exchange" "data_exchange" {
  project          = var.project_id
  location         = var.region
  data_exchange_id = "${local.prefix}${var.name}"
  display_name     = "${local.prefix}${var.name}"
  description      = var.description
  primary_contact  = var.primary_contact
  documentation    = var.documentation
  icon             = var.icon
}

resource "google_bigquery_analytics_hub_listing" "listing" {
  for_each         = local.factory_listings
  project          = var.project_id
  location         = var.region
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.data_exchange.data_exchange_id
  listing_id       = each.key
  display_name     = each.key
  description      = try(each.value.description, null)
  primary_contact  = try(each.value.primary_contact, null)
  documentation    = try(each.value.documentation, null)
  icon             = try(each.value.icon, null)
  request_access   = try(each.value.request_access, null)
  categories       = try(each.value.categories, null)

  bigquery_dataset {
    dataset = each.value.bigquery_dataset
  }

  dynamic "restricted_export_config" {
    for_each = each.value.restricted_export_config != null ? [""] : []
    content {
      enabled               = try(each.value.restricted_export_config.enabled, null)
      restrict_query_result = try(each.value.restricted_export_config.restrict_query_result, null)
    }
  }

}
