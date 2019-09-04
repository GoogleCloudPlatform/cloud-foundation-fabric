variable "audit_viewers" {
  description = "Audit project viewers, in IAM format."
  default     = []
}

variable "billing_account_id" {
  description = "Billing account id used as default for new projects."
  type        = string
}

variable "business_unit_1_name" {
  description = "Business unit 1 short name."
  type        = string
}

variable "business_unit_1_envs" {
  description = "Business unit 1 environments short names."
  type        = list(string)
  default     = ["prod", "test"]
}

variable "business_unit_2_name" {
  description = "Business unit 2 short name."
  type        = string
}

variable "business_unit_2_envs" {
  description = "Business unit 2 environments short names."
  type        = list(string)
  default     = ["prod", "test"]
}

variable "business_unit_3_name" {
  description = "Business unit 3 short name."
  type        = string
}

variable "business_unit_3_envs" {
  description = "Business unit 3 environments short names."
  type        = list(string)
  default     = ["prod", "test"]
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

variable "shared_bindings_members" {
  description = "List of comma-delimited IAM-format members for the additional shared project bindings."
  # example: ["user:a@example.com,b@example.com", "user:c@example.com"]
  default = []
}
variable "shared_bindings_roles" {
  description = "List of roles for additional shared project bindings."
  # example: ["roles/storage.objectViewer", "roles/storage.admin"]
  default = []
}

variable "terraform_owners" {
  description = "Terraform project owners, in IAM format."
  default     = []
}

variable "project_services" {
  description = "Service APIs enabled by default in new projects."
  default = [
    "bigquery-json.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "deploymentmanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "oslogin.googleapis.com",
    "pubsub.googleapis.com",
    "replicapool.googleapis.com",
    "replicapoolupdater.googleapis.com",
    "resourceviews.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com",
  ]
}
