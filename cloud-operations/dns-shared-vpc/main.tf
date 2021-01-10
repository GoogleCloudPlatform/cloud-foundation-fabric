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
module "dns_projects" {
  for_each = toset(var.teams)

  source          = "../../modules/project"
  name            = "${random_id.id.hex}-${each.value}"
  billing_account = var.billing_account
  parent          = var.folder_id

  services = var.project_services
  service_config = {
    disable_on_destroy         = false,
    disable_dependent_services = false
  }
}

# Creating a VPC dedicated to Cloud DNS for each team
module "dns_vpc_network" {
  for_each = toset(var.teams)

  source     = "../../modules/net-vpc"
  project_id = "${random_id.id.hex}-${each.value}"
  name       = "dns-vpc"
  depends_on = [module.dns_projects]
}

# Creating Cloud DNS instance for each team
module "dns-application-private-zone" {
  for_each = toset(var.teams)

  source      = "../../modules/dns"
  project_id  = "${random_id.id.hex}-${each.value}"
  type        = "private"
  name        = each.key
  domain      = "${each.key}.${var.dns_domain}."
  description = "DNS zone for ${each.key}"

  client_networks = [module.dns_vpc_network[each.key].network.self_link]
}

# Creating DNS peerings from Shared VPC Cloud DNS to team Cloud DNS
module "dns-peering-zone" {
  for_each = toset(var.teams)

  source = "../../modules/dns"
  # Extracting project ID from the Shared VPC self link
  project_id  = regex("/projects/(.*?)/.*", var.shared_vpc_link)[0]
  name        = "peering-${each.key}"
  domain      = "${each.key}.${var.dns_domain}."
  description = "DNS peering for ${each.key}"

  type            = "peering"
  peer_network    = module.dns_vpc_network[each.key].network.self_link
  client_networks = [var.shared_vpc_link]
}