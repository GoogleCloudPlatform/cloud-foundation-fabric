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
  oslogin                    = var.oslogin
  oslogin_admins             = var.oslogin_admins
  oslogin_users              = var.oslogin_users
  parent                     = var.parent
  policy_boolean             = var.policy_boolean
  policy_list                = var.policy_list
  prefix                     = var.prefix
  service_encryption_key_ids = var.service_encryption_key_ids
  services                   = var.services
  logging_sinks              = var.logging_sinks
  logging_exclusions         = var.logging_exclusions
  shared_vpc_host_config     = var.shared_vpc_host_config
}

