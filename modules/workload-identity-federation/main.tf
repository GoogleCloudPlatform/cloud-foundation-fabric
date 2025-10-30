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

resource "google_iam_workload_identity_pool" "default" {
  workload_identity_pool_id = var.pool_name
  project                   = var.project_id
  display_name              = var.pool_display_name
  description               = var.pool_description
  disabled                  = var.pool_disabled
}

resource "google_iam_workload_identity_pool_provider" "default" {
  workload_identity_pool_id = google_iam_workload_identity_pool.default.workload_identity_pool_id
  project                   = var.project_id

  workload_identity_pool_provider_id = var.provider_name
  display_name                       = var.provider_display_name
  description                        = var.provider_description
  disabled                           = var.provider_disabled

  attribute_mapping = var.attribute_mapping

  attribute_condition = var.attribute_condition

  dynamic "aws" {
    for_each = var.aws_idp_account_id == null ? [] : [""]
    content {
      account_id = var.aws_idp_account_id
    }
  }

  dynamic "oidc" {
    for_each = var.oidc == null ? [] : [""]
    content {
      issuer_uri        = var.oidc.issuer_uri
      allowed_audiences = var.oidc.allowed_audiences
      jwks_json         = var.oidc.jwks_json
    }
  }

  dynamic "saml" {
    for_each = var.saml_idp_metadata_xml == null ? [] : [""]
    content {
      idp_metadata_xml = var.saml_idp_metadata_xml
    }
  }

  dynamic "x509" {
    for_each = var.x509_pem_certificate_path == null ? [] : [""]
    content {
      trust_store {
        trust_anchors {
          pem_certificate = file(var.x509_pem_certificate_path)
        }
      }
    }

  }

}

# // Example of principal set: member = "principalSet://iam.googleapis.com/projects/733032471643/locations/global/workloadIdentityPools/bitbucket-pool-iata/*"
resource "google_service_account_iam_member" "sa_workload_identity_user_bindings" {
  for_each = var.sa_iam_bindings_additive

  service_account_id = each.key
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.default.name}/${each.value.principal_set_suffix}"
}

// Necessary to allow impersonification
resource "google_service_account_iam_member" "sa_workload_identity_user_bindings_impersonification" {
  for_each = {
    for k, v in var.sa_iam_bindings_additive :
    k => v
    if v.allow_impersonification
  }

  service_account_id = each.key
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.default.name}/${each.value.principal_set_suffix}"
}