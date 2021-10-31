module "cloud_run" {
  source     = "../../../../modules/cloud-run"
  project_id = "my-project"
  name       = "hello"
  revision_name = "blue"
  containers = [{
    image   = "us-docker.pkg.dev/cloudrun/container/hello"
    command = null
    args    = null    
    env     = null
    env_from = null
    ports = null
    resources = null
    volume_mounts = null
  }]
  audit_log_triggers = [
    {
      "service_name": "cloudresourcemanager.googleapis.com",
      "method_name": "SetIamPolicy"
    }
  ]
  pubsub_triggers = [
    "topic1",
    "topic2"
  ]
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
}
