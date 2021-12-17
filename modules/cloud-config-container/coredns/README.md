# Containerized CoreDNS on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized [CoreDNS](https://coredns.io/) service on Container Optimized OS, using the [official image](https://hub.docker.com/r/coredns/coredns/).

The resulting `cloud-config` can be customized in a number of ways:

- a custom CoreDNS configuration can be set using the `coredns_config` variable
- additional files (eg for hosts or zone files) can be passed in via the `files` variable
- a completely custom `cloud-config` can be passed in via the `cloud_config` variable, and additional template variables can be passed in via `config_variables`

The default instance configuration inserts iptables rules to allow traffic on the DNS TCP and UDP ports, and the 8080 port for the optional HTTP health check that can be enabled via the CoreDNS [health plugin](https://coredns.io/plugins/health/).

Logging and monitoring are enabled via the [Google Cloud Logging driver](https://docs.docker.com/config/containers/logging/gcplogs/) configured for the CoreDNS container, and the [Node Problem Detector](https://cloud.google.com/container-optimized-os/docs/how-to/monitoring) service started by default on boot.

The module renders the generated cloud config in the `cloud_config` output, to be used in instances or instance templates via the `user-data` metadata.

For convenience during development or for simple use cases, the module can optionally manage a single instance via the `test_instance` variable. If the instance is not needed the `instance*tf` files can be safely removed. Refer to the [top-level README](../README.md) for more details on the included instance.

## Examples

### Default CoreDNS configuration

This example will create a `cloud-config` that uses the module's defaults, creating a simple DNS forwarder.

```hcl
module "cos-coredns" {
  source           = "./modules/cloud-config-container/coredns"
}

# use it as metadata in a compute instance or template
resource "google_compute_instance" "default" {
  metadata = {
    user-data = module.cos-coredns.cloud_config
  }
```

### Custom CoreDNS configuration

This example will create a `cloud-config` using a custom CoreDNS configuration, that leverages the [CoreDNS hosts plugin]() to serve a single zone via an included `hosts` format file.

```hcl
module "cos-coredns" {
  source           = "./modules/cloud-config-container/coredns"
  coredns_config = "./modules/cloud-config-container/coredns/Corefile-hosts"
  files = {
    "/etc/coredns/example.hosts" = {
      content     = "127.0.0.2 foo.example.org foo"
      owner       = null
      permissions = "0644"
    }
}
```

### CoreDNS instance

This example shows how to create the single instance optionally managed by the module, providing all required attributes in the `test_instance` variable. The instance is purposefully kept simple and should only be used in development, or when designing infrastructures.

```hcl
module "cos-coredns" {
  source           = "./modules/cloud-config-container/coredns"
  test_instance = {
    project_id = "my-project"
    zone       = "europe-west1-b"
    name       = "cos-coredns"
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
| cloud_config | Cloud config template path. If null default will be used. | <code>string</code> |  | <code>&#34;null&#34;</code> |
| config_variables | Additional variables used to render the cloud-config and CoreDNS templates. | <code>map&#40;any&#41;</code> |  | <code>&#123;&#125;</code> |
| coredns_config | CoreDNS configuration path, if null default will be used. | <code>string</code> |  | <code>&#34;null&#34;</code> |
| file_defaults | Default owner and permissions for files. | <code title="object&#40;&#123;&#10;  owner       &#61; string&#10;  permissions &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  owner       &#61; &#34;root&#34;&#10;  permissions &#61; &#34;0644&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| files | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <code title="map&#40;object&#40;&#123;&#10;  content     &#61; string&#10;  owner       &#61; string&#10;  permissions &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| cloud_config | Rendered cloud-config file to be passed as user-data instance metadata. |  |


<!-- END TFDOC -->
