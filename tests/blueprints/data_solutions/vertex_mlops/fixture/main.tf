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

module "projects" {
  source = "../../../../../blueprints/data-solutions/vertex-mlops/"
  labels = {
    "env" : "dev",
    "team" : "ml"
  }
  bucket_name          = "test-dev"
  dataset_name         = "test"
  identity_pool_claims = "attribute.repository/ORGANIZATION/REPO"
  notebooks = {
    "myworkbench" : {
      "owner" : "user@example.com",
      "region" : "europe-west4",
      "subnet" : "default",
    }
  }
  prefix     = "pref"
  project_id = "test-dev"
  project_create = {
    billing_account_id = "000000-123456-123456"
    parent             = "folders/111111111111"
  }
}
