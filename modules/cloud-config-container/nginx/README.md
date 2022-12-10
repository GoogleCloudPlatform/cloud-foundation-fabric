# Containerized Nginx on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized [Nginx](https://nginx.org/en/) service on Container Optimized OS, using the [hello demo image](https://hub.docker.com/r/nginxdemos/hello/).

The resulting `cloud-config` can be customized in a number of ways:

- a custom Nginx configuration can be set in `/etc/nginx/conf.d` using the `nginx_config` variable
- additional files (eg for hosts or zone files) can be passed in via the `files` variable
- a completely custom `cloud-config` can be passed in via the `cloud_config` variable, and additional template variables can be passed in via `config_variables`

The default instance configuration inserts iptables rules to allow traffic on port 80.

Logging and monitoring are enabled via the [Google Cloud Logging agent](https://cloud.google.com/container-optimized-os/docs/how-to/logging) configured for the instance via the `google-logging-enabled` metadata property, and the [Node Problem Detector](https://cloud.google.com/container-optimized-os/docs/how-to/monitoring) service started by default on boot.

The module renders the generated cloud config in the `cloud_config` output, to be used in instances or instance templates via the `user-data` metadata.

For convenience during development or for simple use cases, the module can optionally manage a single instance via the `test_instance` variable. If the instance is not needed the `instance*tf` files can be safely removed. Refer to the [top-level README](../README.md) for more details on the included instance.

## Examples

### Default configuration

This example will create a `cloud-config` that uses the module's defaults, creating a simple hello web server showing host name and request id.

```hcl
module "cos-nginx" {
  source           = "./fabric/modules/cloud-config-container/nginx"
}

module "vm-nginx-tls" {
  source     = "./fabric/modules/compute-vm"
  project_id = "my-project"
  zone       = "europe-west8-b"
  name       = "cos-nginx"
  network_interfaces = [{
    network    = "default"
    subnetwork = "gce"
  }]
  metadata = {
    user-data              = module.cos-nginx.cloud_config
    google-logging-enabled = true
  }
  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
  tags = ["http-server", "ssh"]
}
# tftest modules=1 resources=1
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cloud_config](variables.tf#L17) | Cloud config template path. If null default will be used. | <code>string</code> |  | <code>null</code> |
| [config_variables](variables.tf#L23) | Additional variables used to render the cloud-config and Nginx templates. | <code>map&#40;any&#41;</code> |  | <code>&#123;&#125;</code> |
| [file_defaults](variables.tf#L29) | Default owner and permissions for files. | <code title="object&#40;&#123;&#10;  owner       &#61; string&#10;  permissions &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  owner       &#61; &#34;root&#34;&#10;  permissions &#61; &#34;0644&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [files](variables.tf#L41) | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <code title="map&#40;object&#40;&#123;&#10;  content     &#61; string&#10;  owner       &#61; string&#10;  permissions &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [image](variables.tf#L51) | Nginx container image. | <code>string</code> |  | <code>&#34;nginxdemos&#47;hello:plain-text&#34;</code> |
| [nginx_config](variables.tf#L57) | Nginx configuration path, if null container default will be used. | <code>string</code> |  | <code>null</code> |
| [runcmd_post](variables.tf#L63) | Extra commands to run after starting nginx. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [runcmd_pre](variables.tf#L69) | Extra commands to run before starting nginx. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [users](variables.tf#L75) | List of additional usernames to be created. | <code title="list&#40;object&#40;&#123;&#10;  username &#61; string,&#10;  uid      &#61; number,&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#91;&#10;&#93;">&#91;&#8230;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |

<!-- END TFDOC -->
