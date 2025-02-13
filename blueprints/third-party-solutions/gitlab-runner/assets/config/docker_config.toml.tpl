[[runners]]
  url = "GITLAB_CI_URI"
  name = "RUNNER_NAME"
  token = "RUNNER_TOKEN"
  executor = "docker"
  [runners.docker]
    tls_verify = true
    image = "alpine:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
    network_mtu = 0