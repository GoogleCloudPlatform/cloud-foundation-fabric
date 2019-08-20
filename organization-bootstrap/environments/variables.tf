variable "billing_account_id" {
  description = "Billing account id used as default for new projects."
  type        = string
}

variable "environments" {
  description = "Environment short names."
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

variable "grant_xpn_roles" {
  description = "Grant roles needed for Shared VPC creation to service accounts."
  default     = true
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
