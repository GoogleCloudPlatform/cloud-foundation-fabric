terraform {
  required_version = ">= 1.3.1"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}


