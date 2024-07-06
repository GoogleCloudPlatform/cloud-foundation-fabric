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

# tfdoc:file:description Next-Generation Firewall Enterprise configuration.

locals {
  # Renders to
  # {
  #   euw1a = {
  #     region = europe-west1
  #     zone   = europe-west1-a
  #   },
  #   ...
  # }
  ngfw_endpoint_locations = merge(
    {
      for zone in var.ngfw_enterprise_config.endpoint_primary_region_zones
      : "${local.region_shortnames[var.regions.primary]}${zone}"
      => { region = var.regions.primary, zone = "${var.regions.primary}-${zone}" }
    },
    {
      for zone in var.ngfw_enterprise_config.endpoint_secondary_region_zones
      : "${local.region_shortnames[var.regions.secondary]}${zone}"
      => { region = var.regions.secondary, zone = "${var.regions.secondary}-${zone}" }
    }
  )
}

resource "google_network_security_firewall_endpoint" "firewall_endpoint" {
  for_each = (
    var.ngfw_enterprise_config.enabled
    ? toset(local.ngfw_endpoint_locations)
    : toset([])
  )
  name               = "${var.prefix}-ngfw-endpoint-${each.key}"
  parent             = "organizations/${var.organization.id}"
  location           = each.value.zone
  billing_project_id = module.landing-project.project_id
}
