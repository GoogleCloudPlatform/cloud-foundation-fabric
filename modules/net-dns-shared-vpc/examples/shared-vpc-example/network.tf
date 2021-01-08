module "vpc" {
  source = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v3.3.0"

  project_id = module.project-host.project_id
  name       = "shared-vpc"

  subnets = [
    {
      name               = "subnet-01"
      ip_cidr_range      = "10.10.1.0/24"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

# cloud DNS configuration
module "cloud-dns" {
  source = "../../"

  billing_account = var.billing_account
  folder_id       = google_folder.customer_folder.id
  shared_vpc_link = module.vpc.self_link

  teams      = var.teams
  dns_domain = var.dns_domain
}