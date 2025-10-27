project_id = "test-project"
region     = "region"
name       = "test-run-vpc"
revision = {
  vpc_access = {
    connector       = "projects/test-project/locations/region/connectors/vpc-connector"
    egress_settings = "ALL_TRAFFIC"
  }
}
