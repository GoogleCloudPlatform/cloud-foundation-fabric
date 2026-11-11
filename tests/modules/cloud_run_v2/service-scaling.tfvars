name             = "test-run-scaling"
project_id       = "test-project"
region           = "europe-west8"
managed_revision = false

containers = {
  first = {
    image = "gcr.io/cloudrun/hello"
  }
}

service_config = {
  service_scaling = {
    manual_instance_count = 5
    mode                  = "MANUAL"
  }
}
