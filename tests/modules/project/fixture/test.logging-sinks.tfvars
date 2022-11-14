logging_sinks = {
  warning = {
    destination = "mybucket"
    type        = "storage"
    filter      = "severity=WARNING"
  }
  info = {
    destination = "projects/myproject/datasets/mydataset"
    type        = "bigquery"
    filter      = "severity=INFO"
    disabled    = true
  }
  notice = {
    destination   = "projects/myproject/topics/mytopic"
    type          = "pubsub"
    filter        = "severity=NOTICE"
    unique_writer = true
  }
  debug = {
    destination = "projects/myproject/locations/global/buckets/mybucket"
    type        = "logging"
    filter      = "severity=DEBUG"
    exclusions = {
      no-compute   = "logName:compute"
      no-container = "logName:container"
    }
    unique_writer = true
  }
}
