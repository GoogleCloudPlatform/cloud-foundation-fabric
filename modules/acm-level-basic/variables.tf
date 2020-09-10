variable "device_policies" {
  type    = map(bool)
  default = {}
}

variable "ip_ranges" {
  type    = list(string)
  default = null
}

variable "members" {
  type    = list(string)
  default = null
}

variable "policy" {
  type = string
}

variable "title" {
  type = string
}