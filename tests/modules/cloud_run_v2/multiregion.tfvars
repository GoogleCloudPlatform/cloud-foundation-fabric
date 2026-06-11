name       = "test-run-multiregion"
project_id = "test-project"
region     = "global"

containers = {
  first = {
    image = "gcr.io/cloudrun/hello"
  }
}

service_config = {
  multi_region_settings = {
    regions = ["europe-west8", "europe-west1"]
  }
}
