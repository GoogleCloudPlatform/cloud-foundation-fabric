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
  source     = "../../../../modules/service-directory"
  project_id = "my-project"
  location   = "europe-west1"
  name       = "ns-test"
  iam = {
    "roles/servicedirectory.viewer" = [
      "serviceAccount:service-editor.example.com"
    ]
  }
  services = {
    srv-one = {
      endpoints = ["alpha", "beta"]
      metadata  = null
    }
    srv-two = {
      endpoints = ["alpha"]
      metadata  = null
    }
  }
  service_iam = {
    srv-one = {
      "roles/servicedirectory.editor" = [
        "serviceAccount:service-editor.example.com"
      ]
    }
    srv-two = {
      "roles/servicedirectory.admin" = [
        "serviceAccount:service-editor.example.com"
      ]
    }
  }
  endpoint_config = {
    "srv-one/alpha" = { address = "127.0.0.1", port = 80, metadata = {} }
    "srv-one/beta"  = { address = "127.0.0.2", port = 80, metadata = {} }
    "srv-two/alpha" = { address = "127.0.0.3", port = 80, metadata = {} }
  }
  labels = var.labels
}
