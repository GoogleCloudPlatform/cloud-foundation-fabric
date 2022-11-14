backend_service_configs = {
  default = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
    }]
  }
  video = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig-2"
    }]
  }
}
urlmap_config = {
  default_service = "default"
  host_rules = [{
    hosts        = ["*"]
    path_matcher = "pathmap"
  }]
  path_matchers = {
    pathmap = {
      default_service = "default"
      path_rules = [{
        paths   = ["/video", "/video/*"]
        service = "video"
      }]
    }
  }
}
