# folder for customer
resource "google_folder" "customer_folder" {
  display_name = var.prefix
  parent       = "organizations/${var.organization_id}"
}

# Generating a random id for project ids
resource "random_id" "id" {
  byte_length = 4
}

# Creating the host project
module "project-host" {
  source = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v4.2.0"

  parent          = google_folder.customer_folder.id
  billing_account = var.billing_account
  prefix          = var.prefix
  name            = "${random_id.id.hex}-${var.host_project}"
  services        = var.project_services

  shared_vpc_host_config = {
    enabled          = true
    service_projects = [] # defined later
  }
}

# Note that by default, this module doesn't create the default Network.
module "project-service-1" {
  source = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v4.2.0"

  parent          = google_folder.customer_folder.id
  billing_account = var.billing_account
  prefix          = var.prefix
  name            = "${random_id.id.hex}-${var.service_projects[0]}"
  services        = var.project_services

  shared_vpc_service_config = {
    attach       = true
    host_project = module.project-host.project_id
  }
}

module "project-service-2" {
  source = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v4.2.0"

  parent          = google_folder.customer_folder.id
  billing_account = var.billing_account
  prefix          = var.prefix
  name            = "${random_id.id.hex}-${var.service_projects[1]}"
  services        = var.project_services

  shared_vpc_service_config = {
    attach       = true
    host_project = module.project-host.project_id
  }
}

/*
locals {
  # Adding prefix and random ID before the service project names to generate the service project IDs
  service_projects = [for name in var.service_projects[*] : "${var.prefix}-${random_id.id.hex}-${name}"]
}

module "net-shared-vpc-access" {
  source              = "terraform-google-modules/network/google//modules/fabric-net-svpc-access"
  version             = "~> 2.6"
  host_project_id     = module.project-host.project_id
  service_project_num = length(local.service_projects)
  service_project_ids = local.service_projects
}
*/