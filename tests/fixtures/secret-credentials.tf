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

module "secret-manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = var.project_id
  secrets = {
    credentials = {}
  }
  iam = {
    credentials = {
      "roles/secretmanager.secretAccessor" = [
        "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com",
        "serviceAccount:${var.project_id}@appspot.gserviceaccount.com",
      ]
    }
  }
  versions = {
    credentials = {
      v1 = { enabled = true, data = "manual foo bar spam" }
    }
  }
}
