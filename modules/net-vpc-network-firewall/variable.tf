variable "data_folders" {
  description = "List of paths to folders where firewall configs are stored in yaml format. Folder may include subfolders with configuration files. Files suffix must be `.yaml`."
  type        = list(string)
  default     = null
}

variable "firewall_policy_region" {
  description = "Network firewall policy region."
  type        = string
  default     = null
}

variable "firewall_rules" {
  description = "List rule definitions, default to allow action."
  type = map(object({
    deployment              = optional(string, "global")
    disabled                = optional(bool, false)
    description             = optional(string)
    action                  = optional(string, "allow")
    direction               = optional(string, "INGRESS")
    priority                = optional(number, 1000)
    enable_logging          = optional(bool, false)
    src_secure_tags         = optional(list(string))
    ip_protocol             = optional(string, "all")
    ports                   = optional(list(string))
    target_service_accounts = optional(list(string))
    dest_ip_ranges          = optional(list(string))
    src_ip_ranges           = optional(list(string))
    target_secure_tags      = optional(list(string))


  }))
  default  = {}
  nullable = false
}

variable "global_network" {
  description = "VPC SelfLink to attach the global firewall policy."
  type        = string
  default     = null
}
variable "global_policy_name" {
  description = "Global network firewall policy name."
  type        = string
  default     = null
}

variable "parent_tag" {
  description = "An identifier for the resource with format tagValues/{{name}}"
  type        = string
  default     = "null"
}

variable "project_id" {
  description = "Project id of the project that holds the network."
  type        = string
}

variable "regional_network" {
  description = "VPC SelfLink to attach the regional firewall policy."
  type        = string
  default     = null
}
variable "regional_policy_name" {
  description = "Global network firewall policy name."
  type        = string
  default     = null
}