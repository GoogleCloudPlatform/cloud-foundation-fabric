variable "prefix" {
  description = "Prefix to use for resource names."
  type        = string
}

variable "project_id" {
  description = "The ID of the project where resources will be created."
  type        = string
}

variable "region" {
  description = "Region where resources will be created."
  type        = string
}

variable "zone" {
  description = "Zone where resources will be created."
  type        = string
}

variable "dest_ip_address" {
  description = "On-prem service destination IP address."
  type        = string
}

variable "dest_port" {
  description = "On-prem service destination port."
  type        = string
  default     = "80"
}

variable "producer" {
  description = "Producer configuration."
  type        = object({
    subnet_main     = string # CIDR
    subnet_proxy    = string # CIDR
    subnet_psc      = string # CIDR
    # The accepted projects and related number of allowed PSC endpoints
    accepted_limits = map(number)
  })
}

variable "subnet_consumer" {
  description = "Consumer subnet CIDR."
  type        = string
}
