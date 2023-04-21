project_id  = "my-project"
name        = "test"
bucket_name = var.bucket_name
v2          = var.v2
bundle_config = {
  source_dir  = "bundle"
  output_path = "bundle.zip"
  excludes    = null
}
iam = {
  "roles/cloudfunctions.invoker" = ["allUsers"]
}
