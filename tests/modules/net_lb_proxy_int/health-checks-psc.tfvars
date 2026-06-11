neg_configs = {
  my-psc = {
    psc = {
      region         = "europe-west4"
      target_service = "projects/my-prod-project/regions/europe-west4/serviceAttachments/my-attachment"
    }
  }
}
backend_service_config = {
  backends = [{
    group = "my-psc"
  }]
}
