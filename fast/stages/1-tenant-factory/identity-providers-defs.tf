/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description Identity provider definitions.

locals {
  # tflint-ignore: terraform_unused_declarations
  workforce_identity_providers_defs = {
    azuread = {
      attribute_mapping = {
        "google.subject"       = "assertion.subject"
        "google.display_name"  = "assertion.attributes.userprincipalname[0]"
        "google.groups"        = "assertion.attributes.groups"
        "attribute.first_name" = "assertion.attributes.givenname[0]"
        "attribute.last_name"  = "assertion.attributes.surname[0]"
        "attribute.user_email" = "assertion.attributes.mail[0]"
      }
    }
  }
  workload_identity_providers_defs = {
    # https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
    github = {
      attribute_mapping = {
        "google.subject"             = "assertion.sub"
        "attribute.sub"              = "assertion.sub"
        "attribute.actor"            = "assertion.actor"
        "attribute.repository"       = "assertion.repository"
        "attribute.repository_owner" = "assertion.repository_owner"
        "attribute.ref"              = "assertion.ref"
        "attribute.fast_sub"         = "\"repo:\" + assertion.repository + \":ref:\" + assertion.ref"
      }
      issuer_uri       = "https://token.actions.githubusercontent.com"
      principal_branch = "principalSet://iam.googleapis.com/%s/attribute.fast_sub/repo:%s:ref:refs/heads/%s"
      principal_repo   = "principalSet://iam.googleapis.com/%s/attribute.repository/%s"
    }
    # https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html#token-payload
    gitlab = {
      attribute_mapping = {
        "google.subject"                  = "assertion.sub"
        "attribute.sub"                   = "assertion.sub"
        "attribute.environment"           = "assertion.environment"
        "attribute.environment_protected" = "assertion.environment_protected"
        "attribute.namespace_id"          = "assertion.namespace_id"
        "attribute.namespace_path"        = "assertion.namespace_path"
        "attribute.pipeline_id"           = "assertion.pipeline_id"
        "attribute.pipeline_source"       = "assertion.pipeline_source"
        "attribute.project_id"            = "assertion.project_id"
        "attribute.project_path"          = "assertion.project_path"
        "attribute.repository"            = "assertion.project_path"
        "attribute.ref"                   = "assertion.ref"
        "attribute.ref_protected"         = "assertion.ref_protected"
        "attribute.ref_type"              = "assertion.ref_type"
      }
      issuer_uri       = "https://gitlab.com"
      principal_branch = "principalSet://iam.googleapis.com/%s/attribute.sub/project_path:%s:ref_type:branch:ref:%s"
      principal_repo   = "principalSet://iam.googleapis.com/%s/attribute.repository/%s"
    }
    # https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/workload-identity-tokens#token-structure
    terraform = {
      attribute_mapping = {
        "google.subject"                        = "assertion.terraform_workspace_id"
        "attribute.aud"                         = "assertion.aud"
        "attribute.terraform_run_phase"         = "assertion.terraform_run_phase"
        "attribute.terraform_project_id"        = "assertion.terraform_project_id"
        "attribute.terraform_project_name"      = "assertion.terraform_project_name"
        "attribute.terraform_workspace_id"      = "assertion.terraform_workspace_id"
        "attribute.terraform_workspace_name"    = "assertion.terraform_workspace_name"
        "attribute.terraform_organization_id"   = "assertion.terraform_organization_id"
        "attribute.terraform_organization_name" = "assertion.terraform_organization_name"
        "attribute.terraform_run_id"            = "assertion.terraform_run_id"
        "attribute.terraform_full_workspace"    = "assertion.terraform_full_workspace"
      }
      issuer_uri       = "https://app.terraform.io"
      principal_branch = "principalSet://iam.googleapis.com/%s/attribute.terraform_workspace_id/%s"
      principal_repo   = "principalSet://iam.googleapis.com/%s/attribute.terraform_project_id/%s"
    }
  }
}
