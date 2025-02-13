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

# tfdoc:file:description Per-tenant FAST bootstrap emulation (logging).

module "tenant-log-export-project" {
  source          = "../../../modules/project"
  for_each        = local.fast_tenants
  billing_account = each.value.billing_account.id
  name            = "audit-logs-0"
  parent          = module.tenant-folder[each.key].id
  prefix          = each.value.stage_0_prefix
  iam = {
    "roles/owner" = [
      "serviceAccount:${var.automation.service_accounts.resman}"
    ]
    "roles/viewer" = [
      "serviceAccount:${var.automation.service_accounts.resman-r}"
    ]
  }
  services = [
    # "cloudresourcemanager.googleapis.com",
    # "iam.googleapis.com",
    # "serviceusage.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "stackdriver.googleapis.com"
  ]
}
