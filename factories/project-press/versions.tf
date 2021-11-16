/**
 * Copyright 2021 Google LLC
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

terraform {
  required_version = ">= 1.0.0"

  # When moving into production, please pin the provider and Terraform versions to 
  # a specific version.
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.0.0"
    }
    googleworkspace = {
      source  = "hashicorp/googleworkspace"
      version = ">= 0.5.0"
    }
    #gitlab = {
    #  source  = "gitlabhq/gitlab"
    #  version = ">= 3.7.0"
    #}
    #kubernetes = {
    #  source  = "hashicorp/kubernetes"
    #  version = ">= 2.6.0"
    #}
    #helm = {
    #  source  = "hashicorp/helm"
    #  version = ">= 2.4.0"
    #}
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.1.0"
    }
  }
}
