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

# tfdoc:file:description Workload Identity Federation provider definitions.

locals {
  cicd_provider_defs = {
    github = {
      attribute_mapping = {
        "google.subject"       = "assertion.sub"
        "attribute.sub"        = "assertion.sub"
        "attribute.actor"      = "assertion.actor"
        "attribute.repository" = "assertion.repository"
        "attribute.ref"        = "assertion.ref"
      }
      issuer_uri       = "https://token.actions.githubusercontent.com"
      principal_tpl    = "principal://iam.googleapis.com/%s/subject/repo:%s:ref:refs/heads/%s"
      principalset_tpl = "principalSet://iam.googleapis.com/%s/attribute.repository/%s"
    }
    gitlab = {
      attribute_mapping = {
        "google.subject"       = "assertion.sub"
        "attribute.sub"        = "assertion.sub"
        "attribute.actor"      = "assertion.actor"
        "attribute.repository" = "assertion.repository"
        "attribute.ref"        = "assertion.ref"
      }
      issuer_uri       = "https://token.actions.githubusercontent.com"
      principal_tpl    = "principal://iam.googleapis.com/%s/subject/project_path:%s:ref_type:branch:ref:%s"
      principalset_tpl = "principalSet://iam.googleapis.com/%s/attribute.repository/%s"
    }
  }
}
