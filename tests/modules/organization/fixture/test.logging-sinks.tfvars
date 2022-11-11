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
    filter           = "severity=NOTICE"
    include_children = false
  }
  debug = {
    destination = {
      type   = "logging"
      target = "projects/myproject/locations/global/buckets/mybucket"
    }
    filter           = "severity=DEBUG"
    include_children = false
    exclusions = {
      no-compute   = "logName:compute"
      no-container = "logName:container"
    }
  }
}
