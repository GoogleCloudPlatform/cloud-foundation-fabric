context = {
  addresses = {
    global-ip   = "10.0.32.32"
    existing-ip = "https://www.googleapis.com/compute/v1/projects/foo-test-0/regions/europe-west8/addresses/existing-psc"
  }
  locations = {
    ew8 = "europe-west8"
  }
  networks = {
    test = "https://www.googleapis.com/compute/v1/projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
  project_ids = {
    test = "foo-test-0"
  }
  service_attachments = {
    svc = "projects/foo-producer/regions/europe-west8/serviceAttachments/svc-0"
  }
  subnets = {
    test = "https://www.googleapis.com/compute/v1/projects/foo-dev-net-spoke-0/regions/europe-west8/subnetworks/gce"
  }
}
project_id = "$project_ids:test"
global_apis = {
  googleapis = {
    address = "$addresses:global-ip"
    network = "$networks:test"
    target  = "all-apis"
    service_directory_registration = {
      namespace = "psc-ns"
      region    = "$locations:ew8"
    }
  }
}
published_services = {
  svc-one = {
    global_access = true
    region        = "$locations:ew8"
    subnetwork    = "$subnets:test"
    target        = "$service_attachments:svc"
  }
  svc-existing = {
    address        = "$addresses:existing-ip"
    address_create = false
    region         = "$locations:ew8"
    subnetwork     = "$subnets:test"
    target         = "$service_attachments:svc"
  }
}
regional_apis = {
  storage = {
    address        = "$addresses:existing-ip"
    address_create = false
    global_access  = true
    network        = "$networks:test"
    region         = "$locations:ew8"
    subnetwork     = "$subnets:test"
    target         = "storage.europe-west8.rep.googleapis.com"
  }
}
