force_destroy = true
labels        = { environment = "test" }
logging_config = {
  log_bucket = "foo"
}
name       = "test"
project_id = "test-project"
retention_policy = {
  retention_period = 5
  is_locked        = false
}
storage_class = "MULTI_REGIONAL"
versioning    = true
