variable "atlas_config" {
  description = "MongoDB Atlas configuration."
  type = object({
    cluster_name     = string
    organization_id  = string
    project_name     = string
    region           = string
    database_version = optional(string)
    instance_size    = optional(string)
    provider = object({
      private_key = string
      public_key  = string
    })
  })
}

variable "location" {
  description = "Region where the registries will be created."
  type        = string
  default     = "europe-west8"
}

variable "name" {
  description = "Prefix used for all resource names."
  type        = string
  nullable    = true
  default     = "mongodb"
}

variable "project_id" {
  description = "Project id where the registries will be created."
  type        = string
}
