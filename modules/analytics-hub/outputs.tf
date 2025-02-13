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

output "data_exchange_id" {
  description = "Data exchange id."
  value       = google_bigquery_analytics_hub_data_exchange.data_exchange.data_exchange_id
  depends_on = [
    google_bigquery_analytics_hub_data_exchange.data_exchange,
    google_bigquery_analytics_hub_data_exchange_iam_binding.exchange_iam_bindings,
    google_bigquery_analytics_hub_data_exchange_iam_member.exchange_iam_members
  ]
}

output "data_listings" {
  description = "Data listings and corresponding configs."
  value       = { for k, v in google_bigquery_analytics_hub_listing.listing : k => v.bigquery_dataset }
  depends_on = [
    google_bigquery_analytics_hub_listing.listing,
    google_bigquery_analytics_hub_listing_iam_binding.listing_iam_bindings
  ]
}
