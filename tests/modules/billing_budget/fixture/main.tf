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

module "budget" {
  source                    = "../../../../modules/billing-budget"
  billing_account           = "123456-123456-123456"
  name                      = "my budget"
  projects                  = var.projects
  services                  = var.services
  notify_default_recipients = var.notify_default_recipients
  amount                    = var.amount
  credit_treatment          = var.credit_treatment
  pubsub_topic              = var.pubsub_topic
  notification_channels     = var.notification_channels
  thresholds                = var.thresholds
  email_recipients          = var.email_recipients
}
