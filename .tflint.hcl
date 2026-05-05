plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_required_providers" {
  enabled = false
}

rule "terraform_required_version" {
  enabled = false
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"

  custom_formats = {
    private_snake = {
      description = "snake_case with leading _"
      regex       = "^[_a-z][a-z0-9_]*$"
    }
    kebab = {
      description = "lower kebab case"
      regex       = "^[a-z][a-z0-9-]*$"
    }
  }

  locals {
    format = "private_snake"
  }

  module {
    format = "kebab"
  }
}
