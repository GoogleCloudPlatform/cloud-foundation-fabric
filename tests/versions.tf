# Copyright 2022 Google LLC
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

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    archive = {
      source  = "registry.terraform.io/hashicorp/archive"
      version = ">= 2.2.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 4.6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.6.0"
    }
    local = {
      source  = "registry.terraform.io/hashicorp/local"
      version = ">= 2.1.0"
    }
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = ">= 3.1.0"
    }
    time = {
      source  = "registry.terraform.io/hashicorp/time"
      version = ">= 0.7.2"
    }
  }
}
