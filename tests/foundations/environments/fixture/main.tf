/**
 * Copyright 2021 Google LLC
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
  source               = "../../../../foundations/environments"
  billing_account_id   = var.billing_account_id
  environments         = var.environments
  iam_audit_viewers    = var.iam_audit_viewers
  iam_shared_owners    = var.iam_shared_owners
  iam_terraform_owners = var.iam_terraform_owners
  iam_xpn_config       = var.iam_xpn_config
  organization_id      = var.organization_id
  prefix               = var.prefix
  root_node            = var.root_node
}
