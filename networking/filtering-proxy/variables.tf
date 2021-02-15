variable "billing_account" {
  description = "Billing account id used as default for new projects."
  type        = string
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
}

variable "root_node" {
  description = "Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'."
  type        = string
}

variable "region" {
  description = "Default region for resources"
  type        = string
}

variable "cidrs" {
  description = "CIDR ranges for subnets"
  type        = map(string)
  default = {
    apps  = "10.0.0.0/24"
    proxy = "10.0.1.0/28"
  }
}

variable "nat_logging" {
  description = "Enables Cloud NAT logging if not null, value is one of 'ERRORS_ONLY', 'TRANSLATIONS_ONLY', 'ALL'."
  type        = string
  default     = "ERRORS_ONLY"
}

variable "mig" {
  description = "Enables the creation of an autoscaling managed instance group of squid instances."
  type        = bool
  default     = false
}
