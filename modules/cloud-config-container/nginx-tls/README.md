# Containerized Nginx with self-signed TLS on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized Nginx with a self-signed TLS cert on Container Optimized OS.
This can be useful if you need quickly a VM or instance group answering HTTPS for prototyping.

The generated cloud config is rendered in the `cloud_config` output, and is meant to be used in instances or instance templates via the `user-data` metadata.

This module depends on the [`cos-generic-metadata` module](../cos-generic-metadata) being in the parent folder. If you change its location be sure to adjust the `source` attribute in `main.tf`.

## Examples

### Default configuration

```hcl
# Nginx with self-signed TLS config
module "cos-nginx-tls" {
  source = "./modules/cloud-config-container/nginx-tls"
}

# COS VM
module "vm-nginx-tls" {
  source     = "./modules/compute-vm"
  project_id = local.project_id
  zone       = local.zone
  name       = "cos-nginx-tls"
  network_interfaces = [{
    network    = local.vpc.self_link,
    subnetwork = local.vpc.subnet_self_link,
    nat        = false,
    addresses  = null
  }]

  metadata = {
    user-data = module.cos-nginx-tls.cloud_config
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
|---|---|:---:|:---:|:---:|
| [docker_logging](variables.tf#L23) | Log via the Docker gcplogs driver. Disable if you use the legacy Logging Agent instead. | <code>bool</code> |  | <code>true</code> |
| [nginx_image](variables.tf#L17) | Nginx container image to use. | <code>string</code> |  | <code>&#34;nginx:1.23.1&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |

<!-- END TFDOC -->
