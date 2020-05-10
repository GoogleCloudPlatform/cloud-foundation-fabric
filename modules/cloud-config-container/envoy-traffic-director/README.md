# Containerized Envoy Proxy with Traffic Director on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized Envoy Proxy on Container Optimized OS connected to Traffic Director. The default configuration creates a reverse proxy exposed on the node's port 80. Traffic routing policies and management should be managed by other means via Traffic Director.

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
  zone       = local.zone
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

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| envoy\_image | Envoy Proxy container image to use. | `string` | `"envoyproxy/envoy:v1.14.1"` | no |
| gcp\_logging | Should container logs be sent to Google Cloud Logging | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloud\_config | Rendered cloud-config file to be passed as user-data instance metadata. |
<!-- END TFDOC -->
