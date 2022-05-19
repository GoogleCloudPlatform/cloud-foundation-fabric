variable "billing_account" {
  description = "Billing account id used as default for new projects."
  type        = string
}

variable "location" {
  description = "The location where resources will be deployed."
  type        = string
  default     = "europe"
}

variable "project_name" {
  description = "Name for the project."
  type        = string
}

variable "region" {
  description = "The region where resources will be deployed."
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "The zone where resources will be deployed."
  type        = string
  default     = "b"
}

variable "root_node" {
  description = "The resource name of the parent Folder or Organization. Must be of the form folders/folder_id or organizations/org_id."
  type        = string
}

variable "vpc_ip_cidr_range" {
  description = "Ip range used in the subnet deployed in the project."
  type        = string
  default     = "10.0.0.0/20"
}

variable "vpc_name" {
  description = "Name of the VPC created in the project."
  type        = string
  default     = "data-playground-vpc"
}

variable "vpc_subnet_name" {
  description = "Name of the subnet created in the project."
  type        = string
  default     = "default-subnet"
}
