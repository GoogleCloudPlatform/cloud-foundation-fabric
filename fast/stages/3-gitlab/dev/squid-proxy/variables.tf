#variable "allowed_client_subnets" {
#  description = "List of subnets allowed to access the proxy instance."
#  type        = list(string)
#  default     = [
#    "0.0.0.0/0"
#  ]
#}
#
#variable "allowed_domains" {
#  description = "List of domains allowed by the squid proxy."
#  type        = list(string)
#  default     = [
#    ".google.com",
#    ".github.com",
#    ".pypi.org"
#  ]
#}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "network_config" {
  description = "Shared VPC network configurations to use. If null networks will be created in projects with preconfigured values."
  type        = object({
    network_self_link      = string
    proxy_subnet_self_link = string
  })
  default = null
}

variable "enable_public_ip" {
  description = "Whether to assign public ip to squid-proxy"
  type        = bool
  default     = false
}