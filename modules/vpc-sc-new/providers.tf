provider "google" {
  alias                 = "vpc-sc"
  billing_project       = "tf-playground-simple"
  user_project_override = true
}
