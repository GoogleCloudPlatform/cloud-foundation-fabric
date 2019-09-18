# Copyright 2019 Google LLC
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

output "project-host" {
  description = "VPC host."
  value = {
    project_id     = module.project-svpc-host.project_id
    project_number = module.project-svpc-host.number
  }
}

output "project-data" {
  description = "Data service project."
  value = {
    project_id     = module.project-service-data.project_id
    project_number = module.project-service-data.number
  }
}

output "project-gke" {
  description = "GKE service project."
  value = {
    project_id     = module.project-service-gke.project_id
    project_number = module.project-service-gke.number
  }
}
