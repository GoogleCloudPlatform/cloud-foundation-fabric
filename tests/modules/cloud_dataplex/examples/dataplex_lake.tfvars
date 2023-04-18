name       = "terraform-lake"
prefix     = "test"
project_id = "myproject"
region     = "europe-west2"
zone_name  = "zone"
asset = {
  test_gcs = {
    bucket_name            = "test_gcs"
    cron_schedule          = "15 15 * * *"
    discovery_spec_enabled = true
    resource_spec_type     = "STORAGE_BUCKET"
  }
}
