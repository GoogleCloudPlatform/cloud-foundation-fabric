# Containerized CoreDNS on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized [CoreDNS](https://coredns.io/) service on Container Optimized OS, using the [official image](https://hub.docker.com/r/coredns/coredns/).

The resulting `cloud-config` can be customized in a number of ways:

- a custom CoreDNS configuration can be set using the `coredns_config` variable
- additional files (eg for hosts or zone files) can be passed in via the `files` variable
- a completely custom `cloud-config` can be passed in via the `cloud_config` variable, and additional template variables can be passed in via `config_variables`

The default instance configuration inserts iptables rules to allow traffic on the DNS TCP and UDP ports, and the 8080 port for the optional HTTP health check that can be enabled via the CoreDNS [health plugin](https://coredns.io/plugins/health/).

Logging and monitoring are enabled via the [Google Cloud Logging agent](https://cloud.google.com/container-optimized-os/docs/how-to/logging) configured for the instance via the `google-logging-enabled` metadata property, and the [Node Problem Detector](https://cloud.google.com/container-optimized-os/docs/how-to/monitoring) service is started by default on boot.

The module renders the generated cloud config in the `cloud_config` output, to be used in instances or instance templates via the `user-data` metadata.

For convenience during development or for simple use cases, the module can optionally manage a single instance via the `test_instance` variable. If the instance is not needed the `instance*tf` files can be safely removed. Refer to the [top-level README](../README.md) for more details on the included instance.

## Examples

### Default CoreDNS configuration

This example will create a `cloud-config` that uses the module's defaults, creating a simple DNS forwarder.

```hcl
module "cos-coredns" {
  source           = "./fabric/modules/cloud-config-container/coredns"
}

module "vm" {
  source     = "./fabric/modules/compute-vm"
  project_id = "my-project"
  zone       = "europe-west8-b"
  name       = "cos-coredns"
  network_interfaces = [{
    network    = "default"
    subnetwork = "gce"
  }]
  metadata = {
    user-data              = module.cos-coredns.cloud_config
    google-logging-enabled = true
  }
  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
  tags = ["dns", "ssh"]
}
# tftest modules=1 resources=1
```

### Custom CoreDNS configuration

This example will create a `cloud-config` using a custom CoreDNS configuration, that leverages the [CoreDNS hosts plugin]() to serve a single zone via an included `hosts` format file.

```hcl
module "cos-coredns" {
  source           = "./fabric/modules/cloud-config-container/coredns"
  coredns_config = "./fabric/modules/cloud-config-container/coredns/Corefile-hosts"
  files = {
    "/etc/coredns/example.hosts" = {
      content     = "127.0.0.2 foo.example.org foo"
      owner       = null
      permissions = "0644"
    }
  }  
}
# tftest modules=0 resources=0
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cloud_config](variables.tf#L17) | Cloud config template path. If null default will be used. | <code>string</code> |  | <code>null</code> |
| [config_variables](variables.tf#L23) | Additional variables used to render the cloud-config and CoreDNS templates. | <code>map&#40;any&#41;</code> |  | <code>&#123;&#125;</code> |
| [coredns_config](variables.tf#L29) | CoreDNS configuration path, if null default will be used. | <code>string</code> |  | <code>null</code> |
| [file_defaults](variables.tf#L35) | Default owner and permissions for files. | <code title="object&#40;&#123;&#10;  owner       &#61; string&#10;  permissions &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  owner       &#61; &#34;root&#34;&#10;  permissions &#61; &#34;0644&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [files](variables.tf#L47) | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <code title="map&#40;object&#40;&#123;&#10;  content     &#61; string&#10;  owner       &#61; string&#10;  permissions &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |

<!-- END TFDOC -->
