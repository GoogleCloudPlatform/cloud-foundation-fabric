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
  source               = "../../../../modules/kms"
  iam                  = var.iam
  key_iam              = var.key_iam
  key_purpose          = var.key_purpose
  key_purpose_defaults = var.key_purpose_defaults
  keyring              = var.keyring
  keyring_create       = var.keyring_create
  keys                 = var.keys
  project_id           = var.project_id
}
