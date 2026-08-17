name       = "test-run-traffic"
project_id = "test-project"
region     = "europe-west8"

containers = {
  first = {
    image = "gcr.io/cloudrun/hello"
  }
}

service_config = {
  traffic = [
    {
      percent  = 90
      revision = "test-run-traffic-v1"
      type     = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"
    },
    {
      percent  = 10
      revision = "test-run-traffic-v2"
      tag      = "candidate"
      type     = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"
    }
  ]
}
