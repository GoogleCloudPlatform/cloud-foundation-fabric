variable "billing_account" {
  description = "Billing account associated with the GCP Projects that will be created for each team"
}

variable "prefix" {
  description = "Customer name to use as prefix for resources' naming"
  default     = "test-dns"
}

variable "folder_id" {
  description = "Folder ID in which DNS projects will be created"
}

variable "shared_vpc_link" {
  description = "Shared VPC self link, used for DNS peering"
}

variable "project_services" {
  description = "Service APIs enabled by default"
  default = [
    "compute.googleapis.com",
    "dns.googleapis.com",
  ]
}

variable "teams" {
  description = "List of application teams requiring their own Cloud DNS instance"
  default = [
    "team1",
    "team2",
  ]
}

variable "dns_domain" {
  description = "DNS domain under which each application team DNS domain will be created"
}