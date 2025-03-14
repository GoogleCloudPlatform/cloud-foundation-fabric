variable "mongodbatlas_public_key" {
  description = "MongoDB Atlas Public API Key"
  type        = string
}

variable "mongodbatlas_private_key" {
  description = "MongoDB Atlas Private API Key"
  type        = string
}

variable "atlas_project_name" {
  description = "MongoDB Atlas Project name"
  type        = string
}

variable "atlas_org_id" {
  description = "MongoDB Atlas Org Id"
  type        = string
}

variable "cluster_name" {
  description = "MongoDB Atlas Cluster Name"
  type        = string
}

variable "instance_size" {
  description = ""
  type = string
}

variable "atlas_region" {
  description = ""
  type = string
}

variable "database_version" {
  description = ""
  type = string
}

variable "gcp_project_id" {
  description = ""
  type = string
}

variable "gcp_region" {
  description = ""
  type = string
}

