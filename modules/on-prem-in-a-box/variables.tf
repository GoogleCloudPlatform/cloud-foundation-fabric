variable "project_id" {
  type        = string
  description = "Project id."
}

variable "name" {
  type        = string
  description = "On-prem-in-a-box compute instance name."
  default     = "on-prem-in-a-box"
}

variable "zone" {
  type        = string
  description = "Compute zone."
}

variable "network" {
  type        = string
  description = "VPC network name. "
}

variable "subnet" {
  type        = string
  description = "VPC subnet self link."
}

variable "machine_type" {
  type        = string
  description = "Machine type."
  default     = "g1-small"
}

variable "network_tags" {
  type        = list(string)
  description = "Network tags."
  default     = ["ssh"]
}

variable "vpn_gateway_type" {
  type        = string
  description = "VPN Gateway type, applicable values are `static` and `dynamic`. Input `remote_ip_cidr_ranges` should be provided in case of `static` vpn gateway. "
}


variable "peer_ip" {
  type        = string
  description = "IP Address of Cloud VPN Gateway."
  default     = ""
}

variable "local_ip_cidr_range" {
  type    = string
  default = "192.168.192.0/24"
}

variable "remote_ip_cidr_ranges" {
  type    = list(string)
  default = []
}

variable "shared_secret" {
  type    = string
  default = ""
}
