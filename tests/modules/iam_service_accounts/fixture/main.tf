/**
 * Copyright 2020 Google LLC
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
  source                 = "../../../../modules/iam-service-accounts"
  project_id             = var.project_id
  names                  = ["sa-one", "sa-two", "sa-three"]
  prefix                 = var.prefix
  generate_keys          = var.generate_keys
  iam_members            = var.iam_members
  iam_roles              = var.iam_roles
  iam_billing_roles      = var.iam_billing_roles
  iam_folder_roles       = var.iam_folder_roles
  iam_organization_roles = var.iam_organization_roles
  iam_project_roles      = var.iam_project_roles
  iam_storage_roles      = var.iam_storage_roles
}
