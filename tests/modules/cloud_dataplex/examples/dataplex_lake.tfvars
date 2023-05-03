name       = "terraform-lake"
prefix     = "test"
project_id = "myproject"
region     = "europe-west2"
zones = {
  zone_1 = {
    type      = "RAW"
    discovery = true
    assets = {
      asset_1 = {
        bucket_name            = "asset_1"
        cron_schedule          = "15 15 * * *"
        discovery_spec_enabled = true
        resource_spec_type     = "STORAGE_BUCKET"
      }
    }
  },
  zone_2 = {
    type      = "CURATED"
    discovery = true
    assets = {
      asset_2 = {
        bucket_name            = "asset_2"
        cron_schedule          = "15 15 * * *"
        discovery_spec_enabled = true
        resource_spec_type     = "STORAGE_BUCKET"
      }
    }
  }
}
