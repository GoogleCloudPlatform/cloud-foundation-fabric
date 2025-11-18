/**
 * Copyright 2025 Google LLC
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

locals {
  wif_iam_templates = {
    # https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
    github = {
      apply = "principalSet://iam.googleapis.com/%s/attribute.fast_sub/repo:%s:ref:refs/heads/%s"
      plan  = "principalSet://iam.googleapis.com/%s/attribute.repository/%s"
    }
    # https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html#token-payload
    gitlab = {
      apply = "principalSet://iam.googleapis.com/%s/attribute.sub/project_path:%s:ref_type:branch:ref:%s"
      plan  = "principalSet://iam.googleapis.com/%s/attribute.repository/%s"
    }
    # https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/workload-identity-tokens#token-structure
    terraform = {
      apply = "principalSet://iam.googleapis.com/%s/attribute.terraform_workspace_id/%s"
      plan  = "principalSet://iam.googleapis.com/%s/attribute.terraform_project_id/%s"
    }
    # https://developer.okta.com/docs/api/openapi/okta-oauth/guides/overview/
    okta = {
      apply  = "principalSet://iam.googleapis.com/%s/attribute.sub/project_path:%s:ref_type:branch:ref:%s"
      plan   = "principalSet://iam.googleapis.com/%s/attribute.repository/%s"
      member = "principalSet://iam.googleapis.com/%s/*"
    }
  }
}
