locals {
  schema = jsonencode([
    { name = "data", type = "STRING" },
    { name = "freq", type = "INT64" }
  ])
}

module "bigquery-dataset" {
  source     = "./fabric/modules/bigquery-dataset"
  project_id = var.project_id
  id         = "my_dataset"
  tables = {
    my_table = {
      deletion_protection = false
      schema              = local.schema
      partitioning = {
        time = { type = "DAY", expiration_ms = null }
      }
    }
  }
  iam = {
    "roles/bigquery.dataEditor" = ["serviceAccount:service-${var.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"]
  }
}