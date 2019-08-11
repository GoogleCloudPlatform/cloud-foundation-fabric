variable "root_type" {
  description = "Type of the root for the new hierarchy."
  default     = "folder"
}

variable "root_id" {
  description = "Id of the organization or folder used as the root for the new hierarchy."
  type        = string
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
}

variable "billing_account_id" {
  description = "Billing account id used as default for new projects."
  type        = string
}

variable "terraform_owners" {
  description = "Terraform project owners, in IAM format."
  default     = []
}

variable "gcs_location" {
  description = "GCS bucket location."
  default     = "EU"
}

variable "project_services" {
  description = "Service APIs enabled by default in new projects."
  default = [
    "bigquery-json.googleapis.com",
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

