# Containerized Squid on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized [Squid](http://www.squid-cache.org/) proxy on Container Optimized OS. The default configuration creates a filtering proxy that only allows connection to a whitelisted set of domains.

The resulting `cloud-config` can be customized in a number of ways:

- a custom squid.conf configuration can be set using the `squid_config` variable
- additional files (e.g. additional acls) can be passed in via the `files` variable
- a completely custom `cloud-config` can be passed in via the `cloud_config` variable, and additional template variables can be passed in via `config_variables`

The default instance configuration inserts iptables rules to allow traffic on TCP port 3128. With the default `squid.conf`, deny rules take precedence over allow rules.

Logging and monitoring are enabled via the [Google Cloud Logging agent](https://cloud.google.com/container-optimized-os/docs/how-to/logging) configured for the instance via the `google-logging-enabled` metadata property, and the [Node Problem Detector](https://cloud.google.com/container-optimized-os/docs/how-to/monitoring) service started by default on boot.

The module renders the generated cloud config in the `cloud_config` output, to be used in instances or instance templates via the `user-data` metadata.

For convenience during development or for simple use cases, the module can optionally manage a single instance via the `test_instance` variable. If the instance is not needed the `instance*tf` files can be safely removed. Refer to the [top-level README](../README.md) for more details on the included instance.

## Examples

### Default Squid configuration

This example will create a `cloud-config` that allows any client in the 10.0.0.0/8 CIDR to use the proxy to connect github.com or any subdomain of github.com.

```hcl
module "cos-squid" {
  source           = "./fabric/modules/cloud-config-container/squid"
  allow = [".github.com"]
  clients   = ["10.0.0.0/8"]
}

module "vm" {
  source     = "./fabric/modules/compute-vm"
  project_id = "my-project"
  zone       = "europe-west8-b"
  name       = "cos-squid"
  network_interfaces = [{
    network    = "default"
    subnetwork = "gce"
  }]
  metadata = {
    user-data              = module.cos-squid.cloud_config
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
| [allow](variables.tf#L18) | List of domains Squid will allow connections to. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [clients](variables.tf#L24) | List of CIDR ranges from which Squid will allow connections. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [cloud_config](variables.tf#L30) | Cloud config template path. If null default will be used. | <code>string</code> |  | <code>null</code> |
| [config_variables](variables.tf#L36) | Additional variables used to render the cloud-config and Squid templates. | <code>map&#40;any&#41;</code> |  | <code>&#123;&#125;</code> |
| [default_action](variables.tf#L42) | Default action for domains not matching neither the allow or deny lists. | <code>string</code> |  | <code>&#34;deny&#34;</code> |
| [deny](variables.tf#L52) | List of domains Squid will deny connections to. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [file_defaults](variables.tf#L58) | Default owner and permissions for files. | <code title="object&#40;&#123;&#10;  owner       &#61; string&#10;  permissions &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  owner       &#61; &#34;root&#34;&#10;  permissions &#61; &#34;0644&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [files](variables.tf#L70) | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <code title="map&#40;object&#40;&#123;&#10;  content     &#61; string&#10;  owner       &#61; string&#10;  permissions &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [squid_config](variables.tf#L80) | Squid configuration path, if null default will be used. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |

<!-- END TFDOC -->
