variable "asn_local" {
  type        = number
  description = "ASN for the GCP side of the BGP session"
}

variable "asn_peer" {
  type        = number
  description = "ASN for the remote (on-prem) side of the BGP session"
}

variable "billing_account_id" {
  type        = string
  description = "Billing Account ID the created project will be linked to. Required."
}

variable "cert_domains" {
  type        = list(string)
  description = "List of FQDNs to issue a Google-managed certificate for. Public DNS needs to be updated retrospectively to point these FQDNs to the IP address returned by the module in order for the certificate to be fully emitted."
}

variable "cert_name" {
  type        = string
  description = "Name to use to the Google-managed certificate."
}

variable "dns_zone" {
  type        = string
  description = "Remote (on-prem) DNS zone, for DNS outbound forwarding. This zone will be forwarded to the specified dns resolvers."
}

variable "dns_resolvers" {
  type        = list(string)
  description = "List of remote (on-prem) DNS resolvers to forward requests to. The name servers can be located in the same VPC network or the on-premises network."
}

variable "mappings" {
  type = list(object({
    name        = string
    source      = string
    destination = string
  }))
  description = "List of mappings between frontend and backend URLs. Backend urls are the destination urls. The source domain name identifies which inbound requests will be forwarded to on-prem."
}

variable "master_authorized_ranges" {
  type        = string
  description = "IP range authorized to contact the GKE master. It can be 0.0.0.0/0, but its strongly recommended to set it to trusted IPs that will manage the cluster."
}

variable "name" {
  type        = string
  description = "Unique name within the project to be used for created resources."
  default     = "iap-demo"
}

variable "peer_vpn_ip" {
  type        = string
  description = "IP address of the remote (on-prem) VPN gateway."
}

variable "policy_name" {
  type        = string
  description = "Name of an Access Context Manager policy for the organization, in the form `accessPolicies/{policy_id}`."
  default     = null
}

variable "project_owners" {
  description = "IAP demo project owners, in IAM format."
  type        = list(string)
}

variable "project_id" {
  type        = string
  description = "Project ID where resources will be deployed. The project will be created."
}

variable "range_master" {
  type        = string
  description = "RFC1918 IP range to be used for the GKE master. Must be at least a /28."
}

variable "range_nodes" {
  type        = string
  description = "RFC1918 IP range to be used for the GKE nodes."
}

variable "range_pods" {
  type        = string
  description = "RFC1918 IP range to be used for the GKE pods."
}

variable "range_services" {
  type        = string
  description = "RFC1918 IP range to be used for the GKE services."
}

variable "region" {
  type        = string
  description = "GCP region to deploy resources into."
}

variable "root_node" {
  description = "Hierarchy node where project will be created, 'organizations/org_id' or 'folders/folder_id'."
  type        = string
}

variable "tunnel_0_link_range" {
  type        = string
  description = "IP range (/30) to be used for link of VPN tunnel 0. First IP will be used on-prem, second on GCP."
  default     = "169.254.3.0/30"
}

variable "tunnel_1_link_range" {
  type        = string
  description = "IP range (/30) to be used for link of VPN tunnel 1. First IP will be used on-prem, second on GCP."
  default     = "169.254.4.0/30"
}

variable "shared_secret" {
  type        = string
  description = "Shared Secret used for IPsec Cloud VPN authentication."
}

variable "support_email" {
  type        = string
  description = "Email address of the support group for the IAP OAuth page. The user or service account running the demo needs to be an Owner of such group."
}

variable "web_user_principals" {
  type        = list(string)
  description = "List of IAM principals authorized to access IAP web resources in the project. Non-org principals can only access services once the IAP brand is manually changed to external."
  default     = []
}
