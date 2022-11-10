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

module "test" {
  source                     = "../../../../modules/project"
  name                       = var.name
  billing_account            = var.billing_account
  auto_create_network        = var.auto_create_network
  custom_roles               = var.custom_roles
  iam                        = var.iam
  iam_additive               = var.iam_additive
  iam_additive_members       = var.iam_additive_members
  labels                     = var.labels
  lien_reason                = var.lien_reason
  org_policies               = var.org_policies
  org_policies_data_path     = var.org_policies_data_path
  oslogin                    = var.oslogin
  oslogin_admins             = var.oslogin_admins
  oslogin_users              = var.oslogin_users
  parent                     = var.parent
  prefix                     = var.prefix
  service_encryption_key_ids = var.service_encryption_key_ids
  services                   = var.services
  logging_sinks              = var.logging_sinks
  logging_exclusions         = var.logging_exclusions
  shared_vpc_host_config     = var.shared_vpc_host_config
}

module "test-svpc-service" {
  source              = "../../../../modules/project"
  count               = var._test_service_project ? 1 : 0
  name                = "test-svc"
  billing_account     = var.billing_account
  auto_create_network = false
  parent              = var.parent
  services            = var.services
  shared_vpc_service_config = {
    attach       = true
    host_project = module.test.project_id
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices", "container-engine"
      ]
      "roles/vpcaccess.user" = [
        "cloudrun"
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
    }
  }
}
