# Containerized Gitlab CE on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized [Gitlab CE](https://docs.gitlab.com/ee/install/docker.html) service on Container Optimized OS, using the [official image](https://hub.docker.com/r/gitlab/gitlab-ce/).

The module supports a few out of the box options for configuring the installation:

- `env` and `env_file` variables to set the container environment (see below for ways to use them to configure Gitlab)
- `hostname` variable to set the container hostname
- `image` to change or pin the container image
- `mounts` to define optional disks and mountpoints for the container volumes used for Gitlab config, data and logs (defaults to boot disk filesystem)

The module also allows replacing the cloud config template with a custom one, and specifying arbitrary template values via the `cloud_config` and `config_variables` variables.

The default cloud config also

- adds iptables rules to allow traffic on ports 80 and 443
- enables logging via the [Google Cloud Logging driver](https://docs.docker.com/config/containers/logging/gcplogs/)
- starts the [Node Problem Detector](https://cloud.google.com/container-optimized-os/docs/how-to/monitoring) service for monitoring

The module renders the generated cloud config in the `cloud_config` output, to be used in instances or instance templates via the `user-data` metadata.

## Gitlab configuration

For details on configuring Gitlab options you can refer to these sections in the official documentation:

- [Pre-configure Docker container](https://docs.gitlab.com/ee/install/docker.html#pre-configure-docker-container)
- [Environment variables](https://docs.gitlab.com/ee/administration/environment_variables.html)
- [Setting custom environment variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html)
- [Configuration settings](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template) which can be specified in the `GITLAB_OMNIBUS_CONFIG` variable

## Examples

### Local Filesystems

The default value of the `mounts` variable sets the `device_name` attributes to to `null`, which results in using local folders under `/run/gitlab` for Gitlab config, data and logs.

```hcl
module "gitlab-ce" {
  source   = "./modules/cloud-config-container/gitlab-ce"
  hostname = "gitlab.example.com"
}
```

Local paths under `/run/gitlab` can be changed via the `fs_path` attribute:

```hcl
module "gitlab-ce" {
  source   = "./modules/cloud-config-container/gitlab-ce"
  hostname = "gitlab.example.com"
  mounts   = {
    config = { device_name = null, fs_path = "my-config" }
    data   = { device_name = null, fs_path = "my-data" }
    logs   = { device_name = null, fs_path = "logs" }
  }
}
```

### Additional disks

Additional disks can be specified in the `mounts` variable by setting device names (the last part of a device `/dev/disk/by-id/google-[name]` file) in the `device_name` attributes. The `fs_path` attributes define the actual paths within the device filesystems that are passed to the container volumes.

```hcl
module "gitlab-ce" {
  source   = "./modules/cloud-config-container/gitlab-ce"
  hostname = "gitlab.example.com"
  mounts   = {
    config = { device_name = "data", fs_path = "config" }
    data   = { device_name = "data", fs_path = "data" }
    logs   = { device_name = "logs", fs_path = null }
  }
}
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cloud_config](variables.tf#L17) | Cloud-config template path. If null default will be used. | <code>string</code> |  | <code>null</code> |
| [config_variables](variables.tf#L23) | Additional template variables passed to the cloud-config template. | <code>map&#40;any&#41;</code> |  | <code>&#123;&#125;</code> |
| [env](variables.tf#L29) | Environment variables for the gitlab-ce container. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [env_file](variables.tf#L36) | Environment variables file for the gitlab-ce container. | <code>string</code> |  | <code>null</code> |
| [hostname](variables.tf#L42) | Hostname passed to the gitlab-ce container. | <code>string</code> |  | <code>null</code> |
| [image](variables.tf#L48) | Gitlab-ce container image. | <code>string</code> |  | <code>&#34;gitlab&#47;gitlab-ce:latest&#34;</code> |
| [mounts](variables.tf#L54) | Disk device names and paths in the disk filesystem for the gitlab-ce container paths. | <code title="object&#40;&#123;&#10;  config &#61; object&#40;&#123;&#10;    device_name &#61; string&#10;    fs_path     &#61; string&#10;  &#125;&#41;&#10;  data &#61; object&#40;&#123;&#10;    device_name &#61; string&#10;    fs_path     &#61; string&#10;  &#125;&#41;&#10;  logs &#61; object&#40;&#123;&#10;    device_name &#61; string&#10;    fs_path     &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  config &#61; &#123; device_name &#61; null, fs_path &#61; &#34;config&#34; &#125;&#10;  data   &#61; &#123; device_name &#61; null, fs_path &#61; &#34;data&#34; &#125;&#10;  logs   &#61; &#123; device_name &#61; null, fs_path &#61; &#34;logs&#34; &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |

<!-- END TFDOC -->
