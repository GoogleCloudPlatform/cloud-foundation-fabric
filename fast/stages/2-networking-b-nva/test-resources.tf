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

# tfdoc:file:description Temporary instances for testing

locals {
  test-vms = merge(
    {
      dev-spoke-primary = {
        network    = module.dev-spoke-vpc.self_link
        project_id = module.dev-spoke-project.project_id
        region     = var.regions.primary
        subnetwork = module.dev-spoke-vpc.subnet_self_links["${var.regions.primary}/dev-default"]
        tags       = [local.region_shortnames[var.regions.primary]]
        zone       = "b"
      }
      dev-spoke-secondary = {
        network    = module.dev-spoke-vpc.self_link
        project_id = module.dev-spoke-project.project_id
        region     = var.regions.secondary
        subnetwork = module.dev-spoke-vpc.subnet_self_links["${var.regions.secondary}/dev-default"]
        tags       = [local.region_shortnames[var.regions.secondary]]
        zone       = "b"
      }
      dmz-primary = {
        network    = module.dmz-vpc.self_link
        project_id = module.landing-project.project_id
        region     = var.regions.primary
        subnetwork = module.dmz-vpc.subnet_self_links["${var.regions.primary}/dmz-default"]
        tags       = [local.region_shortnames[var.regions.primary]]
        zone       = "b"
      }
      dmz-secondary = {
        network    = module.dmz-vpc.self_link
        project_id = module.landing-project.project_id
        region     = var.regions.secondary
        subnetwork = module.dmz-vpc.subnet_self_links["${var.regions.secondary}/dmz-default"]
        tags       = [local.region_shortnames[var.regions.secondary]]
        zone       = "b"
      }
      landing-primary = {
        network    = module.landing-vpc.self_link
        project_id = module.landing-project.project_id
        region     = var.regions.primary
        subnetwork = module.landing-vpc.subnet_self_links["${var.regions.primary}/landing-default"]
        tags       = [local.region_shortnames[var.regions.primary]]
        zone       = "b"
      }
      landing-secondary = {
        network    = module.landing-vpc.self_link
        project_id = module.landing-project.project_id
        region     = var.regions.secondary
        subnetwork = module.landing-vpc.subnet_self_links["${var.regions.secondary}/landing-default"]
        tags       = [local.region_shortnames[var.regions.secondary]]
        zone       = "b"
      }
      prod-spoke-primary = {
        network    = module.prod-spoke-vpc.self_link
        project_id = module.prod-spoke-project.project_id
        region     = var.regions.primary
        subnetwork = module.prod-spoke-vpc.subnet_self_links["${var.regions.primary}/prod-default"]
        tags       = [local.region_shortnames[var.regions.primary]]
        zone       = "b"
      }
      prod-spoke-secondary = {
        network    = module.prod-spoke-vpc.self_link
        project_id = module.prod-spoke-project.project_id
        region     = var.regions.secondary
        subnetwork = module.prod-spoke-vpc.subnet_self_links["${var.regions.secondary}/prod-default"]
        tags       = [local.region_shortnames[var.regions.secondary]]
        zone       = "b"
      }
    },
    (var.network_mode == "regional_vpc") ?
    {
      regional-vpc-primary = {
        network    = module.regional-primary-vpc[0].self_link
        project_id = module.landing-project.project_id
        region     = var.regions.primary
        subnetwork = module.regional-primary-vpc[0].subnet_self_links["${var.regions.primary}/regional-default"]
        tags       = [local.region_shortnames[var.regions.primary]]
        zone       = "b"
      }
      regional-vpc-secondary = {
        network    = module.regional-secondary-vpc[0].self_link
        project_id = module.landing-project.project_id
        region     = var.regions.secondary
        subnetwork = module.regional-secondary-vpc[0].subnet_self_links["${var.regions.secondary}/regional-default"]
        tags       = [local.region_shortnames[var.regions.secondary]]
        zone       = "b"
      }
    } : {}
  )
}

module "test-vms" {
  for_each = var.create_test_instances ? local.test-vms : {}
  # for_each   = {}
  source     = "../../../modules/compute-vm"
  project_id = each.value.project_id
  zone       = "${each.value.region}-${each.value.zone}"
  name       = "test-vm-${each.key}"
  network_interfaces = [{
    network = each.value.network
    # change the subnet name to match the values you are actually using
    subnetwork = each.value.subnetwork
  }]
  instance_type = "e2-micro"
  tags = concat(
    ["ssh"],
    each.value.tags == null ? [] : each.value.tags
  )
  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-11"
    }
  }
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install -y iputils-ping bind9-dnsutils
    EOF
  }
}
