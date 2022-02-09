variable "billing_account_id" {
  description = "Billing account id."
  type        = string
  default     = "012345-67890A-BCDEF0"
}

variable "data_dir" {
  description = "Relative path for the folder storing configuration data."
  type        = string
  default     = "./projects/"
}

variable "environment_dns_zone" {
  description = "DNS zone suffix for environment."
  type        = string
  default     = "prod.gcp.example.com"
}

variable "defaults_file" {
  description = "Relative path for the file storing the project factory configuration."
  type        = string
  default     = "./defaults.yaml"
}

variable "shared_vpc_self_link" {
  description = "Self link for the shared VPC."
  type        = string
  default     = "self-link"
}

variable "vpc_host_project" {
  # tfdoc:variable:source 02-networking
  description = "Host project for the shared VPC."
  type        = string
  default     = "host-project"
}
