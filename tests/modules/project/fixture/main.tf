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
  source              = "../../../../modules/project"
  name                = "my-project"
  billing_account     = "12345-12345-12345"
  auto_create_network = var.auto_create_network
  custom_roles        = var.custom_roles
  iam_members         = var.iam_members
  iam_roles           = var.iam_roles
  iam_nonauth_members = var.iam_nonauth_members
  iam_nonauth_roles   = var.iam_nonauth_roles
  labels              = var.labels
  lien_reason         = var.lien_reason
  oslogin             = var.oslogin
  oslogin_admins      = var.oslogin_admins
  oslogin_users       = var.oslogin_users
  parent              = var.parent
  prefix              = var.prefix
  services            = var.services
}
