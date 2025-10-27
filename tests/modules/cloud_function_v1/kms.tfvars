project_id  = "project"
region      = "region"
name        = "test-cf-kms"
bucket_name = "bucket"
bundle_config = {
  path = "gs://assets/sample-function.zip"
}
kms_key = "kms_key_id"
repository_settings = {
  repository = "artifact_registry_id"
}
