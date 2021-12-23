# Containerized Nginx on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized [Nginx](https://nginx.org/en/) service on Container Optimized OS, using the [hello demo image](https://hub.docker.com/r/nginxdemos/hello/).

The resulting `cloud-config` can be customized in a number of ways:

- a custom Nginx configuration can be set in `/etc/nginx/conf.d` using the `nginx_config` variable
- additional files (eg for hosts or zone files) can be passed in via the `files` variable
- a completely custom `cloud-config` can be passed in via the `cloud_config` variable, and additional template variables can be passed in via `config_variables`

The default instance configuration inserts iptables rules to allow traffic on port 80.

Logging and monitoring are enabled via the [Google Cloud Logging driver](https://docs.docker.com/config/containers/logging/gcplogs/) configured for the CoreDNS container, and the [Node Problem Detector](https://cloud.google.com/container-optimized-os/docs/how-to/monitoring) service started by default on boot.

The module renders the generated cloud config in the `cloud_config` output, to be used in instances or instance templates via the `user-data` metadata.

For convenience during development or for simple use cases, the module can optionally manage a single instance via the `test_instance` variable. If the instance is not needed the `instance*tf` files can be safely removed. Refer to the [top-level README](../README.md) for more details on the included instance.

## Examples

### Default configuration

This example will create a `cloud-config` that uses the module's defaults, creating a simple hello web server showing host name and request id.

```hcl
module "cos-nginx" {
  source           = "./modules/cloud-config-container/nginx"
}

# use it as metadata in a compute instance or template
resource "google_compute_instance" "default" {
  metadata = {
    user-data = module.cos-nginx.cloud_config
  }
```

### Nginx instance

This example shows how to create the single instance optionally managed by the module, providing all required attributes in the `test_instance` variable. The instance is purposefully kept simple and should only be used in development, or when designing infrastructures.

```hcl
module "cos-nginx" {
  source           = "./modules/cloud-config-container/nginx"
  test_instance = {
    project_id = "my-project"
    zone       = "europe-west1-b"
    name       = "cos-nginx"
    type       = "f1-micro"
    network    = "default"
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/my-subnet"
  }
}
```

<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| cloud_config | Cloud config template path. If null default will be used. | <code>string</code> |  | <code>null</code> |
| config_variables | Additional variables used to render the cloud-config and Nginx templates. | <code>map&#40;any&#41;</code> |  | <code>&#123;&#125;</code> |
| file_defaults | Default owner and permissions for files. | <code title="object&#40;&#123;&#10;  owner       &#61; string&#10;  permissions &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  owner       &#61; &#34;root&#34;&#10;  permissions &#61; &#34;0644&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| files | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <code title="map&#40;object&#40;&#123;&#10;  content     &#61; string&#10;  owner       &#61; string&#10;  permissions &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| image | Nginx container image. | <code>string</code> |  | <code>&#34;nginxdemos&#47;hello:plain-text&#34;</code> |
| nginx_config | Nginx configuration path, if null container default will be used. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| cloud_config | Rendered cloud-config file to be passed as user-data instance metadata. |  |


<!-- END TFDOC -->
