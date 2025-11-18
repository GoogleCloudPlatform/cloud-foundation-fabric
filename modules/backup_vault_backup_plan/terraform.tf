terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>7.11.0"
    }
  }
}

provider "google" {}
