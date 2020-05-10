# Generic cloud-init generator for Container Optimized OS

This helper module manages a `cloud-config` configuration that can start a container on [Container Optimized OS](https://cloud.google.com/container-optimized-os/docs) (COS). Either a complete `cloud-config` template can be provided via the `cloud_config` variable with optional template variables via the `config_variables`, or a generic `cloud-config` can be generated based on typical parameters needed to start a container.

Logging can be enabled via the [Google Cloud Logging docker driver](https://docs.docker.com/config/containers/logging/gcplogs/) using the `gcp_logging` variable. This is enabled by default, but requires that the service account running the COS instance have the `roles/logging.logWriter` IAM role or equivalent permissions on the project. If it doesn't, the container will fail to start unless this is disabled.

The module renders the generated cloud config in the `cloud_config` output, which can be directly used in instances or instance templates via the `user-data` metadata attribute.

## Examples

### Default configuration

This example will create a `cloud-config` that starts [Envoy Proxy](https://www.envoyproxy.io) and expose it on port 80. For a complete example, look at the sibling [`envoy-traffic-director`](../envoy-traffic-director/README.md) module that uses this module to start Envoy Proxy and connect it to [Traffic Director](https://cloud.google.com/traffic-director).

```hcl
module "cos-envoy" {
  source = "./modules/cos-generic-metadata"

  container_image = "envoyproxy/envoy:v1.14.1"
  container_name  = "envoy"
  container_args  = "-c /etc/envoy/envoy.yaml --log-level info --allow-unknown-static-fields"

  container_volumes = [
    { host      = "/etc/envoy/envoy.yaml",
      container = "/etc/envoy/envoy.yaml"
    }
  ]

  docker_args = "--network host --pid host"

  files = {
    "/var/run/envoy/customize.sh" = {
      content     = file("customize.sh")
      owner       = "root"
      permissions = "0744"
    }
    "/etc/envoy/envoy.yaml" = {
      content     = file("envoy.yaml")
      owner       = "root"
      permissions = "0644"
    }
  }

  run_commands = [
    "iptables -t nat -N ENVOY_IN_REDIRECT",
    "iptables -t nat -A ENVOY_IN_REDIRECT -p tcp -j REDIRECT --to-port 15001",
    "iptables -t nat -A PREROUTING -p tcp -m tcp --dport 80 -j ENVOY_IN_REDIRECT",
    "iptables -t filter -A INPUT -p tcp -m tcp --dport 15001 -m state --state NEW,ESTABLISHED -j ACCEPT",
    "/var/run/envoy/customize.sh",
    "systemctl daemon-reload",
    "systemctl start envoy",
  ]

  users = [
    {
      username = "envoy",
      uid      = 1337
    }
  ]
}
```

<!-- BEGIN TFDOC -->
## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| container\_image | Container image. | `string` | n/a | yes |
| boot\_commands | List of cloud-init `bootcmd`s | `list(string)` | `[]` | no |
| cloud\_config | Cloud config template path. If provided, takes precedence over all other arguments. | `string` | `null` | no |
| config\_variables | Additional variables used to render the template passed via `cloud_config` | `map(any)` | `{}` | no |
| container\_args | Arguments for container | `string` | `""` | no |
| container\_name | Name of the container to be run | `string` | `"container"` | no |
| container\_volumes | List of volumes | <pre>list(object({<br>    host      = string,<br>    container = string<br>  }))</pre> | `[]` | no |
| docker\_args | Extra arguments to be passed for docker | `string` | `null` | no |
| file\_defaults | Default owner and permissions for files. | <pre>object({<br>    owner       = string<br>    permissions = string<br>  })</pre> | <pre>{<br>  "owner": "root",<br>  "permissions": "0644"<br>}</pre> | no |
| files | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <pre>map(object({<br>    content     = string<br>    owner       = string<br>    permissions = string<br>  }))</pre> | `{}` | no |
| gcp\_logging | Should container logs be sent to Google Cloud Logging | `bool` | `true` | no |
| run\_commands | List of cloud-init `runcmd`s | `list(string)` | `[]` | no |
| users | List of usernames to be created. If provided, first user will be used to run the container. | <pre>list(object({<br>    username = string,<br>    uid      = number,<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloud\_config | Rendered cloud-config file to be passed as user-data instance metadata. |
<!-- END TFDOC -->
