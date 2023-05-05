project_id = "my-project"
instances = {
  instance-test-ew1 = {
    region                        = "europe-west1"
    environments                  = ["apis-test"]
    runtime_ip_cidr_range         = "10.0.4.0/22"
    troubleshooting_ip_cidr_range = "10.1.1.0.0/28"
  }
}
