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

data "google_client_config" "identity" {
  count = var.credentials_config.fleet_host != null ? 1 : 0
}

provider "kubernetes" {
  config_path = (
    var.credentials_config.kubeconfig == null
    ? null
    : pathexpand(var.credentials_config.kubeconfig.path)
  )
  config_context = try(
    var.credentials_config.kubeconfig.context, null
  )
  host = (
    var.credentials_config.fleet_host == null
    ? null
    : var.credentials_config.fleet_host
  )
  token = try(data.google_client_config.identity.0.access_token, null)
}
