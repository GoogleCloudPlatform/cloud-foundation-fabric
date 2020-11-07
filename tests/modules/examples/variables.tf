# common variables used for examples
variable "organization_id" {
  default = "organization/organization"
}

variable "project_id" {
  default = "projects/project-id"
}

variable "billing_account_id" {
  default = "billing_account_id"
}

variable "bucket" {
  default = "bucket"
}

variable "region" {
  default = "region"
}

variable "zone" {
  default = "zone"
}

variable "vpc" {
  default = {
    name      = "vpc_name"
    self_link = "vpc_self_link"
  }
}

variable "subnet" {
  default = {
    name      = "subnet_name"
    region    = "subnet_region"
    cidr      = "subnet_cidr"
    self_link = "subnet_self_link"
  }
}

variable "kms_key" {
  default = {
    self_link = "kms_key_self_link"
  }
}

variable "service_account" {
  default = {
    id        = "service_account_id"
    email     = "service_account_email"
    iam_email = "service_account_iam_email"
  }
}
