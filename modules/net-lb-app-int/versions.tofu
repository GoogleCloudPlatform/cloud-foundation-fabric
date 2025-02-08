# Copyright 2025 Google LLC
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

# Fabric release: v37.1.0

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.19.0, < 7.0.0" # tftest
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.19.0, < 7.0.0" # tftest
    }
  }
  provider_meta "google" {
    module_name = "google-pso-tool/cloud-foundation-fabric/modules/net-lb-app-int:v37.1.0-tofu"
  }
  provider_meta "google-beta" {
    module_name = "google-pso-tool/cloud-foundation-fabric/modules/net-lb-app-int:v37.1.0-tofu"
  }
}
