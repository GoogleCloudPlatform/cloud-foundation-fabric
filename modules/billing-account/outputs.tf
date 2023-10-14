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

output "billing_budget_ids" {
  description = "Billing budget ids."
  value = {
    for k, v in google_billing_budget.default :
    k => v.id
  }
}

output "monitoring_notification_channel_ids" {
  description = "Monitoring notification channel ids."
  value = {
    for k, v in google_monitoring_notification_channel.default :
    k => v.id
  }
}
