# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

data_defaults = {
  billing_account           = "1245-5678-9012"
  storage_location          = "EU"
  prefix                    = "my-prefix"
  parent                    = "folders/1234"
  shared_vpc_service_config = null
}
data_merges = {
  services = [
    "stackdriver.googleapis.com"
  ]
}
data_overrides = {
  prefix = "myprefix"
}
# location where the yaml files are read from
factories_config = {
  projects_data_path = "projects"
  context = {
    folder_ids = {
      default = "folders/5678901234"
      teams   = "folders/4321056789"
    }
    vpc_host_projects = {
      dev-spoke-0 = "test-pf-dev-net-spoke-0"
    }
  }
}
