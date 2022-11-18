project_create = {
  billing_account_id = "12345-12345-12345"
  parent             = "folders/123456789"
}
project_id = "my-project"
envgroups = {
  test = ["test.cool-demos.space"]
}
environments = {
  apis-test = {
    envgroups = ["test"]
  }
}
instances = {
  instance-ew1 = {
    region            = "europe-west1"
    environments      = ["apis-test"]
    psa_ip_cidr_range = "10.0.4.0/22"
  }
}
psc_config = {
  europe-west1 = "10.0.0.0/28"
}