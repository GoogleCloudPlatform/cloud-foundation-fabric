project_id  = "my-project"
name        = "test"
bucket_name = "mybucket"
bundle_config = {
  source_dir  = "../../tests/modules/cloud_function/bundle"
  output_path = "bundle.zip"
  excludes    = null
}
iam = {
  "roles/cloudfunctions.invoker" = ["allUsers"]
}
