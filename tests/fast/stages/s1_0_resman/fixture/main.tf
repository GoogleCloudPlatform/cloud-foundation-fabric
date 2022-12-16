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

module "stage" {
  source = "../../../../../fast/stages/01-resman"
  automation = {
    federated_identity_pool      = null
    federated_identity_providers = null
    project_id                   = "fast-prod-automation"
    project_number               = 123456
    outputs_bucket               = "test"
  }
  billing_account = {
    id              = "000000-111111-222222"
    organization_id = 123456789012
  }
  custom_roles = {
    # organization_iam_admin = "organizations/123456789012/roles/organizationIamAdmin",
    service_project_network_admin = "organizations/123456789012/roles/xpnServiceAdmin"
  }
  groups = {
    gcp-billing-admins      = "gcp-billing-admins",
    gcp-devops              = "gcp-devops",
    gcp-network-admins      = "gcp-network-admins",
    gcp-organization-admins = "gcp-organization-admins",
    gcp-security-admins     = "gcp-security-admins",
    gcp-support             = "gcp-support"
  }
  organization = {
    domain      = "fast.example.com"
    id          = 123456789012
    customer_id = "C00000000"
  }
  prefix = "fast2"
}
