variable "project_id" {
  description = "Project id, references existing project if `project_create` is null."
  type        = string
}

variable "network_interfaces" {
  description = "Network interfaces configuration. Use self links for Shared VPC, set addresses to null if not needed."
  type = list(object({
    nat        = optional(bool, false)
    network    = string
    subnetwork = string
    addresses = optional(object({
      internal = string
      external = string
    }), null)
    alias_ips = optional(map(string), {})
    nic_type  = optional(string)
  }))
}

variable "data_dir" {
  description = "Relative path for the folder storing configuration data."
  type        = string
  default     = "data/vms/"
}