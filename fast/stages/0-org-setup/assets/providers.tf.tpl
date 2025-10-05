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

terraform {
  backend "gcs" {
    bucket                      = "${bucket}"
    %{~ if try(universe_domain, null) == null ~}
    impersonate_service_account = "${service_account}"
    %{~ endif ~}
    %{~ if try(prefix, null) != null ~}
    prefix = "${prefix}"
    %{~ endif ~}
    %{~ if try(universe_domain, null) != null ~}
    storage_custom_endpoint = "https://storage.${universe_domain}/storage/v1/b"
    %{~ endif ~}
  }
}
provider "google" {
  impersonate_service_account = "${service_account}"
  %{~ if try(universe_domain, null) != null ~}
  universe_domain = "${universe_domain}"
  %{~ endif ~}
}
provider "google-beta" {
  impersonate_service_account = "${service_account}"
  %{~ if try(universe_domain, null) != null ~}
  universe_domain = "${universe_domain}"
  %{~ endif ~}
}
