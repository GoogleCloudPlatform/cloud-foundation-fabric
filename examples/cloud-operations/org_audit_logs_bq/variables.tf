variable "dataset_id" {
  description = "Dataset id to store the routed logs"
  type        = string
}

variable "exclusions" {
  description = "Logging exclusions for the sink in the form {NAME -> FILTER}."
  type        = map(string)
  default     = {}
}

variable "filter" {
  description = "The filter to apply when exporting logs"
  type        = string
}

variable "location" {
  description = "Dataset location"
  type        = string
  default     = "EU"
}

variable "org_id" {
  description = "Organization Id"
  type        = string
}

variable "prefix" {
  description = "Prefix used to generate project id and name."
  type        = string
  default     = null
}

variable "project_create" {
  description = "Provide values if project creation is needed, uses existing project if null. Parent is in 'folders/nnn' or 'organizations/nnn' format."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "project_id" {
  description = "Project id, references existing project if `project_create` is null."
  type        = string
}