variable "application_title" {
  type    = string
  default = "Cloud IAP protected Application"
}

variable "client_name" {
  type    = string
  default = "IAP Client"
}

variable "create_client" {
  type    = bool
  default = true
}

variable "project_id" {
  type    = string
  default = null
}

variable "support_email" {
  type = string
}