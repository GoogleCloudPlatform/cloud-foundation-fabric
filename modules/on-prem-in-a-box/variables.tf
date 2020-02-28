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

variable "subnet_self_link" {
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
}

variable "peer_bgp_session_range" {
  type        = string
  description = "Peer BGP sesison range of the BGP interface."
  default     = "169.254.0.1/30"
}

variable "local_bgp_session_range" {
  type        = string
  description = "Local BGP sesison range of the BGP interface."
  default     = "169.254.0.2/30"
}

variable "peer_bgp_asn" {
  type        = string
  description = "Peer BGP ASN."
  default     = "65001"
}

variable "local_bgp_asn" {
  type        = string
  description = "Local BGP ASN."
  default     = "65002"
}

variable "local_ip_cidr_range" {
  type    = string
  default = "192.168.192.0/24"
}

variable "remote_ip_cidr_ranges" {
  description = "List of comma separated remote CIDR ranges"
  type        = string
  default     = ""
}

variable "shared_secret" {
  type    = string
  default = ""
}
