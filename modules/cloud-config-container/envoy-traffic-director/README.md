# Containerized Envoy Proxy with Traffic Director on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized Envoy Proxy on Container Optimized OS connected to Traffic Director. The default configuration creates a reverse proxy exposed on the node's port 80. Traffic routing policies and management should be managed by other means via Traffic Director.

The generated cloud config is rendered in the `cloud_config` output, and is meant to be used in instances or instance templates via the `user-data` metadata.

This module depends on the [`cos-generic-metadata` module](../cos-generic-metadata) being in the parent folder. If you change its location be sure to adjust the `source` attribute in `main.tf`.

## Examples

### Default configuration

```hcl
module "cos-envoy-td" {
  source = "./fabric/modules/cloud-config-container/envoy-traffic-director"
}

module "vm" {
  source     = "./fabric/modules/compute-vm"
  project_id = "my-project"
  zone       = "europe-west8-b"
  name       = "cos-envoy-td"
  network_interfaces = [{
    network    = "default"
    subnetwork = "gce"
  }]
  metadata = {
    user-data              = module.cos-envoy-td.cloud_config
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
| [envoy_image](variables.tf#L17) | Envoy Proxy container image to use. | <code>string</code> |  | <code>&#34;envoyproxy&#47;envoy:v1.15.5&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |

<!-- END TFDOC -->
