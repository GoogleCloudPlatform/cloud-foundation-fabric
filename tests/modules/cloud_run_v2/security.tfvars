# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

name       = "test-run-security"
project_id = "test-project"
region     = "europe-west8"

containers = {
  first = {
    image = "gcr.io/cloudrun/hello"
  }
}

binary_authorization = {
  use_default = true
}

service_config = {
  default_uri_disabled = true
}
