project_id  = "test-project"
region      = "region"
name        = "test-cf-vpc"
bucket_name = "bucket"
bundle_config = {
  path = "gs://assets/sample-function.zip"
}
vpc_connector = {
  name            = "projects/test-project/locations/region/connectors/vpc-connector"
  egress_settings = "ALL_TRAFFIC"
}
