variable "billing_account_id" {
  description = "Billing account id used as default for new projects."
  type        = string
}

variable "tf_project_id" {
  description = "Id of a project where service accounts and terraform state buckets should be created"
  type        = string
}

variable "top_level_folder_name" {
  description = "Top level folder name."
  type        = string
}

variable "second_level_folders_names" {
  description = "Second level folders names."
  type        = list(string)
}

variable "generate_service_account_keys" {
  description = "Generate and store service account keys in the state file."
  default     = false
}

variable "gcs_location" {
  description = "GCS bucket location."
  default     = "EU"
}

variable "organization_id" {
  description = "Organization id."
  type        = string
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
}

variable "root_node" {
  description = "Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'."
  type        = string
}



