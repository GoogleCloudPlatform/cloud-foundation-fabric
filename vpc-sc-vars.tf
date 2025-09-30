variable "vpc_sc" {
  description = "VPC-SC configuration for the project, use when `ignore_changes` for resources is set in the VPC-SC module."
  type = object({
    perimeter_name    = string
    perimeter_bridges = optional(list(string), [])
    is_dry_run        = optional(bool, false)
  })
  default = null
}
