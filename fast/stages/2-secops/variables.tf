

variable "essential_contacts" {
  description = "Email used for essential contacts, unset if null."
  type        = string
  default     = null
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "workforce_identity_providers" {
  description = "Workforce Identity Federation pools."
  type = map(object({
    attribute_condition = optional(string)
    issuer              = string
    display_name        = string
    description         = string
    disabled            = optional(bool, false)
    saml = optional(object({
      idp_metadata_xml = string
    }), null)
  }))
  default  = {}
  nullable = false
}
