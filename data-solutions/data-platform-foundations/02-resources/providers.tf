provider "google" {
  impersonate_service_account = "data-platform-main@${var.project_ids.services}.iam.gserviceaccount.com"
}
provider "google-beta" {
  impersonate_service_account = "data-platform-main@${var.project_ids.services}.iam.gserviceaccount.com"
}