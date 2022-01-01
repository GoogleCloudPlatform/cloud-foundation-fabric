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
  source     = "../../../../modules/secret-manager"
  project_id = "my-project"
  iam = {
    secret-1 = {
      "roles/secretmanager.secretAccessor" = [
        "serviceAccount:service-account.example.com"
      ]
    }
    secret-2 = {
      "roles/secretmanager.viewer" = [
        "serviceAccount:service-account.example.com"
      ]
    }
  }
  secrets = {
    secret-1 = ["europe-west1"],
    secret-2 = null
  }
  versions = {
    secret-1 = {
      foobar = { enabled = true, data = "foobar" }
    }
  }
  labels = var.labels
}
