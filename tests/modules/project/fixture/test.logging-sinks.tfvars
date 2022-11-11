logging_sinks = {
  warning = {
    destination = {
      type   = "storage"
      target = "mybucket"
    }
    filter = "severity=WARNING"
  }
  info = {
    destination = {
      type   = "bigquery"
      target = "projects/myproject/datasets/mydataset"
    }
    filter   = "severity=INFO"
    disabled = true
  }
  notice = {
    destination = {
      type   = "pubsub"
      target = "projects/myproject/topics/mytopic"
    }
    filter        = "severity=NOTICE"
    unique_writer = true
  }
  debug = {
    destination = {
      type   = "logging"
      target = "projects/myproject/locations/global/buckets/mybucket"
    }
    filter = "severity=DEBUG"
    exclusions = {
      no-compute   = "logName:compute"
      no-container = "logName:container"
    }
    unique_writer = true
  }
}
