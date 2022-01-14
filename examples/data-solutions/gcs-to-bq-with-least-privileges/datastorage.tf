###############################################################################
#                                   GCS                                       #
###############################################################################

module "gcs-data" {
  source        = "../../../modules/gcs"
  project_id    = module.project.project_id
  prefix        = var.prefix
  name          = "data"
  location      = var.region
  storage_class = "REGIONAL"
  # encryption_key = module.kms.keys.key-gcs.id
  force_destroy = true
}

module "gcs-df-tmp" {
  source        = "../../../modules/gcs"
  project_id    = module.project.project_id
  prefix        = var.prefix
  name          = "df-tmp"
  location      = var.region
  storage_class = "REGIONAL"
  # encryption_key = module.kms.keys.key-gcs.id
  force_destroy = true
}

###############################################################################
#                                   BQ                                        #
###############################################################################

module "bigquery-dataset" {
  source     = "../../../modules/bigquery-dataset"
  project_id = module.project.project_id
  id         = "datalake"
  # Define Tables in Terraform for the porpuse of the example. 
  # Probably in a production environment you would handle Tables creation in a 
  # separate Terraform State or using a different tool/pipeline (for example: Dataform).
  tables = {
    person = {
      friendly_name = "Person. Dataflow import."
      labels        = {}
      options       = null
      partitioning = {
        field = null
        range = null # use start/end/interval for range
        time  = null
      }
      schema              = file("${path.module}/person.json")
      deletion_protection = false
    }
  }
}
