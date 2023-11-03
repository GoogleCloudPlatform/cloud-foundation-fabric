# Containerized Envoy as SNI dynamic forward proxy on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized [Envoy SNI Dynamic forward proxy]https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/sni_dynamic_forward_proxy_filter) service on Container Optimized OS running on port 443.

This module depends on the cos-generic-metadata module being in the parent folder. If you change its location be sure to adjust the source attribute in main.tf.

Logging and monitoring are enabled via the [Google Cloud Logging agent](https://cloud.google.com/container-optimized-os/docs/how-to/logging) configured for the instance via the `google-logging-enabled` metadata property, and the [Node Problem Detector](https://cloud.google.com/container-optimized-os/docs/how-to/monitoring) service started by default on boot.

## Examples

### Default configuration

This example will create a `cloud-config` that uses the module's defaults, creating a simple hello web server showing host name and request id.

```hcl
module "cos-envoy-sni-dyn-fwd-proxy" {
  source      = "./fabric/modules/cloud-config-container/envoy-sni-dyn-fwd-proxy"
  envoy_image = "envoyproxy/envoy:v1.28-latest"
}

module "vm-envoy-sni-dyn-fwd-proxy" {
  source     = "./fabric/modules/compute-vm"
  project_id = "my-project"
  zone       = "europe-west8-b"
  name       = "cos-envoy-sni-dyn-fw-proxy"
  network_interfaces = [{
    network    = "default"
    subnetwork = "gce"
  }]
  metadata = {
    user-data              = module.cos-envoy-sni-dyn-fwd-proxy.cloud_config
    google-logging-enabled = true
  }
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      type  = "pd-ssd"
      size  = 10
    }
  }
  tags = ["https-server", "ssh"]
}
# tftest modules=1 resources=1
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [envoy_image](variables.tf#L17) | Image. | <code>string</code> | ✓ |  |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |
<!-- END TFDOC -->
