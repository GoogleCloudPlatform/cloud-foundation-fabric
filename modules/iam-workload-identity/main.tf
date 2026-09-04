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

locals {
  _ctx_p = "$"
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local._ctx_p}${k}:${kk}" => vv
    } if !endswith(k, "_vars")
  }
  pool_id = "${local.prefix}${var.name}"
  pool_name = format(
    "projects/%s/locations/global/workloadIdentityPools/%s",
    local.project_id,
    local.pool_id
  )
  prefix     = var.prefix == null ? "" : "${var.prefix}-"
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
}

resource "google_iam_workload_identity_pool" "default" {
  provider                  = google
  project                   = local.project_id
  workload_identity_pool_id = local.pool_id
  display_name              = var.display_name
  description               = var.description
  disabled                  = var.disabled
}

resource "google_iam_workload_identity_pool_provider" "default" {
  for_each = var.identity_providers
  provider = google
  project  = local.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default.workload_identity_pool_id
  )
  workload_identity_pool_provider_id = "${local.prefix}${each.key}"
  display_name                       = each.value.display_name
  description                        = each.value.description
  disabled                           = each.value.disabled
  attribute_condition                = each.value.attribute_condition
  attribute_mapping                  = each.value.attribute_mapping

  dynamic "aws" {
    for_each = each.value.aws != null ? [each.value.aws] : []
    content {
      account_id = aws.value.account_id
    }
  }

  dynamic "oidc" {
    for_each = each.value.oidc != null ? [each.value.oidc] : []
    content {
      allowed_audiences = oidc.value.allowed_audiences
      issuer_uri        = oidc.value.issuer_uri
      jwks_json         = oidc.value.jwks_json
    }
  }

  dynamic "saml" {
    for_each = each.value.saml != null ? [each.value.saml] : []
    content {
      idp_metadata_xml = saml.value.idp_metadata_xml
    }
  }
}
