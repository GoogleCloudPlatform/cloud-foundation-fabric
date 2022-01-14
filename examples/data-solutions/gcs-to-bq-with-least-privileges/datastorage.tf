###############################################################################
#                                   GCS                                       #
###############################################################################

module "gcs-01" {
  source        = "../../../modules/gcs"
  for_each      = toset(["data-landing", "df-tmplocation"])
  project_id    = module.project-service.project_id
  prefix        = module.project-service.project_id
  name          = each.key
  force_destroy = true
}

###############################################################################
#                                   BQ                                        #
###############################################################################

module "bigquery-dataset" {
  source     = "../../../modules/bigquery-dataset"
  project_id = module.project-service.project_id
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
