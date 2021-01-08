/**
 * Copyright 2020 Google LLC
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

# Generating a random id for project ids
resource "random_id" "id" {
  byte_length = 2
  prefix      = var.prefix
}

# Creating a GCP project for each team for Cloud DNS
resource "google_project" "dns_projects" {
  for_each = toset(var.teams)

  name                = "dns-${each.value}"
  project_id          = "${random_id.id.hex}-${each.value}"
  folder_id           = var.folder_id
  billing_account     = var.billing_account
  auto_create_network = false
}

# Enabling DNS and Compute APIs
resource "google_project_service" "compute_api" {
  for_each = toset(var.teams)

  project = "${random_id.id.hex}-${each.value}"
  service = "compute.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "dns_api" {
  for_each = toset(var.teams)

  project = "${random_id.id.hex}-${each.value}"
  service = "dns.googleapis.com"

  disable_dependent_services = true
}

# Creating a VPC dedicated to Cloud DNS for each team
resource "google_compute_network" "dns_vpc_network" {
  for_each = toset(var.teams)

  name                    = "dns-vpc"
  project                 = "${random_id.id.hex}-${each.value}"
  auto_create_subnetworks = false
}

# Creating a map of Projet IDs => network self links for DNS application projects
locals {
  networks_map = {
    for network in google_compute_network.dns_vpc_network :
    network.project => network.self_link
  }
}

# Creating Cloud DNS instance for each team
resource "google_dns_managed_zone" "application-dns-zone" {
  for_each = toset(var.teams)

  name        = each.key
  project     = "${random_id.id.hex}-${each.value}"
  dns_name    = "${each.key}.${var.dns_domain}."
  description = "DNS zone for ${each.key}"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = local.networks_map["${random_id.id.hex}-${each.value}"]
    }
  }
}

# Creating DNS peerings from env Cloud DNS to team Cloud DNS
resource "google_dns_managed_zone" "peering-zone" {
  provider = google-beta
  for_each = toset(var.teams)

  name = "peering-${each.key}"
  # Extracting project ID from the Shared VPC self link
  project     = regex("/projects/(.*?)/.*", var.shared_vpc_link)[0]
  dns_name    = "${each.key}.${var.dns_domain}."
  description = "DNS peering for ${each.key}"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = var.shared_vpc_link
    }
  }

  peering_config {
    target_network {
      network_url = local.networks_map["${random_id.id.hex}-${each.value}"]
    }
  }
}