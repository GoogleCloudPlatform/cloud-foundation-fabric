# Copyright 2024 Google LLC
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

data "archive_file" "bundle" {}
resource "azuread_user" "default" {}
resource "azurerm_resource_group" "default" {}
#resource "github_branch" "default" { provider = github }
resource "google_service_account" "sa1" {}
resource "google_service_account" "sa2" { provider = google-beta }
resource "local_file" "default" {}
resource "random_pet" "default" {}
resource "time_static" "default" {}
resource "tls_private_key" "default" {}
resource "vsphere_role" "default" {}
