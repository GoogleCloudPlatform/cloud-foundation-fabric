context = {
  networks = {
    test = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
  project_ids = {
    test = "foo-test-0"
  }
}
project_id = "$project_ids:test"
name       = "googleapis"
networks = {
  landing = "$networks:test"
}
rules = {
  pubsub = {
    dns_name = "pubsub.googleapis.com."
    local_data = {
      A = {
        rrdatas = ["199.36.153.4", "199.36.153.5"]
      }
    }
  }
}
