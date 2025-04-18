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

# tfdoc:file:description Workforce Identity provider definitions.

locals {
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
    okta = {
      attribute_mapping = {
        "google.subject"       = "assertion.subject"
        "google.display_name"  = "assertion.subject"
        "google.groups"        = "assertion.attributes.groups"
        "attribute.first_name" = "assertion.attributes.firstName[0]"
        "attribute.last_name"  = "assertion.attributes.lastName[0]"
        "attribute.user_email" = "assertion.attributes.email[0]"
      }
    }
  }
}
