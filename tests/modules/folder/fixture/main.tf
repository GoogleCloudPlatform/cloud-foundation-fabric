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
  source                      = "../../../../modules/folder"
  parent                      = "organizations/12345678"
  name                        = "folder-a"
  group_iam                   = var.group_iam
  iam                         = var.iam
  iam_additive                = var.iam_additive
  iam_additive_members        = var.iam_additive_members
  firewall_policies           = var.firewall_policies
  firewall_policy_association = var.firewall_policy_association
  logging_sinks               = var.logging_sinks
  logging_exclusions          = var.logging_exclusions
  org_policies                = var.org_policies
  org_policies_data_path      = var.org_policies_data_path
}
