# Containerized Envoy Proxy with Traffic Director on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized Envoy Proxy on Container Optimized OS connected to Traffic Director. The default configuration creates a reverse proxy exposed on the node's port 80. Traffic routing policies and management should be managed by other means via Traffic Director.

The generated cloud config is rendered in the `cloud_config` output, and is meant to be used in instances or instance templates via the `user-data` metadata.

This module depends on the [`cos-generic-metadata` module](../cos-generic-metadata) being in the parent folder. If you change its location be sure to adjust the `source` attribute in `main.tf`.

## Examples

### Default configuration

```hcl
# Envoy TD config
module "cos-envoy-td" {
  source = "./modules/cloud-config-container/envoy-traffic-director"
}

# COS VM
module "vm-cos" {
  source     = "./modules/compute-vm"
  project_id = local.project_id
  region     = local.region
  name       = "cos-envoy-td"
  network_interfaces = [{
    network    = local.vpc.self_link,
    subnetwork = local.vpc.subnet_self_link,
    nat        = false,
    addresses  = null
  }]
  instance_count = 1
  tags           = ["ssh", "http"]

  metadata = {
    user-data = module.cos-envoy-td.cloud_config
  }

  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }

  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
}
```


<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| *envoy_image* | Envoy Proxy container image to use. | <code title="">string</code> |  | <code title="">envoyproxy/envoy:v1.14.1</code> |
| *gcp_logging* | Should container logs be sent to Google Cloud Logging | <code title="">bool</code> |  | <code title="">true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| cloud_config | Rendered cloud-config file to be passed as user-data instance metadata. |  |
<!-- END TFDOC -->
