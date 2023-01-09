/**
 * Copyright 2023 Google LLC
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

# tfdoc:file:description Secrets.

module "passwords" {
  source     = "../../../modules/secret-manager"
  project_id = module.project.project_id
  secrets = {
    (local.secret_id)         = null
    (local.keyfile_secret_id) = null
  }
  iam = {
    (local.secret_id) = {
      "roles/secretmanager.secretAccessor" = [module.service-account.iam_email]
    }
    (local.keyfile_secret_id) = {
      "roles/secretmanager.secretAccessor" = [module.service-account.iam_email]
    }
  }
  versions = {
    (local.secret_id) = {
      v1 = {
        enabled = true
        data    = random_password.administrator.result
      }
    }
    (local.keyfile_secret_id) = {
      v1 = {
        enabled = true
        data    = random_password.keyfile.result
      }
    }
  }
}

# Keyfile for MongoDB replica set authentication
resource "random_password" "keyfile" {
  length  = 256
  special = false
}

resource "random_password" "administrator" {
  length  = 12
  special = false
}
