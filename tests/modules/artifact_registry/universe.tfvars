/**
 * Copyright 2026 Google LLC
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

project_id = "eu0:myproject"
location   = "u-germany-northeast1"
name       = "myregistry"
format     = { docker = { standard = {} } }
iam = {
  "roles/artifactregistry.admin" = ["group:cicd@example.com"]
}
universe = {
  package_domain = "pkg-berlin-build0.goog"
  prefix         = "eu0"
}
