project_id = "my-project"
location   = "europe-west1"
name       = "cluster-1"
vpc_config = {
  network    = "default"
  subnetwork = "default"
}
monitoring_config = {
  advanced_datapath_observability = {
    enable_metrics = true
    enable_relay   = true
  }
}
