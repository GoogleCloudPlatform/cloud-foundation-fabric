variable "container_configuration" {
  type = object({
    image                 = string
    container_port        = number
    container_concurrency = number
    timeout_seconds       = number
    traffic_percent       = number
    latest_revision       = bool

  })

  default = {
    image                 = "gcr.io/cloudrun/hello"
    container_port        = 8080
    container_concurrency = 50
    timeout_seconds       = 100
    traffic_percent       = 100
    latest_revision       = true
  }

}

variable "method_list" {
  type    = list(string)
  default = ["google.admin.AdminService.addGroupMember"]
}

variable "org_id" {
  type = string
}
variable "project_id" {
  type = string
}
variable "region" {
  type    = string
  default = "us-central1"
}
