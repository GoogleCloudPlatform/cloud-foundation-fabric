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

# Non-HashiCorp providers used across the repository, matching their module
# constraints. Kept in an _override.tf file so Terraform merges
# required_providers with versions.tf.

terraform {
  required_providers {
    # Commented out due to large provider binary size; uncomment if needed
    # when mirroring providers locally for recipe-vpn-aws-gcp.
    # aws = {
    #   source  = "hashicorp/aws"
    #   version = "~> 6.0"
    # }
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 16.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.17"
    }
    restful = {
      source  = "magodo/restful"
      version = "= 0.21.0"
    }
  }
}
