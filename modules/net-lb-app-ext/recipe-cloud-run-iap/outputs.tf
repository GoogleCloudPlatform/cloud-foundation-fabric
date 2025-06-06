/**
 * Copyright 2025 Google LLC
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
  command_tpl = <<EOT
curl -v -H "Authorization: Bearer $(gcloud auth print-identity-token \
--audiences $${aud} \
--impersonate-service-account $${sa} \
--include-email)" $${url}
EOT
}

output "application_service_account_email" {
  description = "Application service account email."
  value       = module.application_service_account.email
}

output "command" {
  description = "Command."
  value = templatestring(local.command_tpl, {
    aud = google_iap_client.iap_client.client_id
    sa  = module.application_service_account.email
    url = local.url
  })
}

output "oauth2_client_id" {
  description = "OAuth client ID."
  value       = google_iap_client.iap_client.client_id
}

output "url" {
  description = "URL to access service exposed by IAP."
  value       = local.url
}
