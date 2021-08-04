variable "name" {
    description = "Apigee instance name."
    type = string
}

variable "apigee_org_id" {
    description = "Apigee Organization ID"
    type = string
}

variable "apigee_environments" {
  description = "Apigee Environment Names."
  type = list(string)
  default = []
}

variable "cidr_mask" {
    description = "CIDR mask for the Apigee instance"
    type        = number
    validation {
    condition     = contains([16, 20, 22], var.cidr_mask)
    error_message = "Allowed Values for cidr_mask [16, 20, 22]."
  }
}

variable "region" {
  description = "Compute region."
  type        = string
}
