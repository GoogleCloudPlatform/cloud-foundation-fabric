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

# tfdoc:file:description Workforce Identity Federation provider definitions.

locals {
  wfif_attribute_mappings = {
    azuread = {
      "google.subject"       = "assertion.subject"
      "google.display_name"  = "assertion.attributes.userprincipalname[0]"
      "google.groups"        = "assertion.attributes.groups"
      "attribute.first_name" = "assertion.attributes.givenname[0]"
      "attribute.last_name"  = "assertion.attributes.surname[0]"
      "attribute.user_email" = "assertion.attributes.mail[0]"
    }
    okta = {
      "google.subject"       = "assertion.subject"
      "google.display_name"  = "assertion.subject"
      "google.groups"        = "assertion.attributes.groups"
      "attribute.first_name" = "assertion.attributes.firstName[0]"
      "attribute.last_name"  = "assertion.attributes.lastName[0]"
      "attribute.user_email" = "assertion.attributes.email[0]"
    }
  }
}

resource "google_iam_workforce_pool" "default" {
  count             = var.workforce_identity_config == null ? 0 : 1
  parent            = var.organization_id
  location          = "global"
  workforce_pool_id = var.workforce_identity_config.pool_name
}

resource "google_iam_workforce_pool_provider" "default" {
  for_each            = try(var.workforce_identity_config.providers, {})
  provider_id         = each.key
  attribute_condition = each.value.attribute_condition
  description         = each.value.description
  disabled            = each.value.disabled
  display_name        = each.value.display_name
  attribute_mapping = merge(
    try(local.wfif_attribute_mappings[each.value.attribute_mapping_template], {}),
    each.value.attribute_mapping
  )
  location          = google_iam_workforce_pool.default[0].location
  workforce_pool_id = google_iam_workforce_pool.default[0].workforce_pool_id
  dynamic "saml" {
    for_each = each.value.identity_provider.saml == null ? [] : [""]
    content {
      idp_metadata_xml = each.value.identity_provider.saml.idp_metadata_xml
    }
  }
  dynamic "oidc" {
    for_each = each.value.identity_provider.oidc == null ? [] : [""]
    content {
      issuer_uri = each.value.identity_provider.oidc.issuer_uri
      client_id  = each.value.identity_provider.oidc.client_id
      jwks_json  = each.value.identity_provider.oidc.jwks_json
      dynamic "client_secret" {
        for_each = (
          each.value.identity_provider.oidc.client_secret == null ? [] : [""]
        )
        content {
          value {
            plain_text = each.value.identity_provider.oidc.client_secret
          }
        }
      }
      dynamic "web_sso_config" {
        for_each = (
          each.value.identity_provider.oidc.web_sso_config == null ? [] : [""]
        )
        content {
          response_type = (
            each.value.identity_provider.oidc.web_sso_config.response_type
          )
          assertion_claims_behavior = (
            each.value.identity_provider.oidc.web_sso_config.assertion_claims_behavior
          )
          additional_scopes = (
            each.value.identity_provider.oidc.web_sso_config.additional_scopes
          )
        }
      }
    }
  }
  dynamic "extra_attributes_oauth2_client" {
    for_each = (
      try(each.value.oauth2_client_config.extra_attributes, null) == null ? [] : [""]
    )
    content {
      issuer_uri = (
        each.value.oauth2_client_config.extra_attributes.issuer_uri
      )
      client_id = (
        each.value.oauth2_client_config.extra_attributes.client_id
      )
      attributes_type = (
        each.value.oauth2_client_config.extra_attributes.attributes_type
      )
      dynamic "client_secret" {
        for_each = (
          each.value.oauth2_client_config.extra_attributes.client_secret == null ? [] : [""]
        )
        content {
          value {
            plain_text = each.value.oauth2_client_config.extra_attributes.client_secret
          }
        }
      }
      dynamic "query_parameters" {
        for_each = (
          each.value.oauth2_client_config.extra_attributes.query_filter == null ? [] : [""]
        )
        content {
          filter = each.value.oauth2_client_config.extra_attributes.query_filter
        }
      }
    }
  }
  dynamic "extended_attributes_oauth2_client" {
    for_each = (
      try(each.value.oauth2_client_config.extended_attributes, null) == null ? [] : [""]
    )
    content {
      issuer_uri = (
        each.value.oauth2_client_config.extended_attributes.issuer_uri
      )
      client_id = (
        each.value.oauth2_client_config.extended_attributes.client_id
      )
      attributes_type = (
        each.value.oauth2_client_config.extended_attributes.attributes_type
      )
      dynamic "client_secret" {
        for_each = (
          each.value.oauth2_client_config.extended_attributes.client_secret == null ? [] : [""]
        )
        content {
          value {
            plain_text = each.value.oauth2_client_config.extended_attributes.client_secret
          }
        }
      }
      dynamic "query_parameters" {
        for_each = (
          each.value.oauth2_client_config.extended_attributes.query_filter == null ? [] : [""]
        )
        content {
          filter = each.value.oauth2_client_config.extended_attributes.query_filter
        }
      }
    }
  }
}
