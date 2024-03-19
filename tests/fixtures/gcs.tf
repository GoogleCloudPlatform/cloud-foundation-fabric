
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = var.project_id
  prefix     = var.prefix
  name       = "my-bucket"
  iam = {
    "roles/storage.admin" = ["serviceAccount:service-${var.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"]
  }
}