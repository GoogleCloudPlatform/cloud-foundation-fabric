variable "address_name" {
  type    = string
  default = null
}

variable "cert_domains" {
  type    = list(string)
  default = null
}

variable "cert_name" {
  type    = string
  default = null
}

variable "iap_client_id" {
  type = string
}

variable "iap_client_secret" {
  type = string
}


variable "mappings" {
  type = list(object({
    name        = string
    source      = string
    destination = string
  }))
  default = []
}



variable "name" {
  type = string
}

variable "web_user_principals" {
  type    = list(string)
  default = null
}

variable "project_id" {
  type = string
}
