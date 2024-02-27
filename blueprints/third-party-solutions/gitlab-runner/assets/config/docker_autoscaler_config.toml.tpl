[[runners]]
  url = "GITLAB_CI_URI"
  name = "RUNNER_NAME"
  token = "RUNNER_TOKEN"
  shell = "sh"                                        # use powershell or pwsh for Windows Images

  executor = "docker-autoscaler"

  # Docker Executor config
  [runners.docker]
    image = "alpine:latest"

  # Autoscaler config
  [runners.autoscaler]
    plugin = "fleeting-plugin-googlecompute"

    capacity_per_instance = 5
    max_use_count = 1
    max_instances = 10

    [runners.autoscaler.plugin_config] # plugin specific configuration (see plugin documentation)
      name             = "${mig_name}" # GCP Instance Group name
      project          = "${gcp_project_id}"
      zone             = "${zone}"
      # credentials_file = "/home/user/.config/gcloud/application_default_credentials.json" # optional, default is '~/.config/gcloud/application_default_credentials.json'

    [runners.autoscaler.connector_config]
      username          = "runner"
      use_external_addr = false

    [[runners.autoscaler.policy]]
      idle_count = 5
      idle_time = "20m0s"