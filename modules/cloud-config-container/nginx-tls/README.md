# Containerized Nginx with self-signed TLS on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized Nginx with a self-signed TLS cert on Container Optimized OS. This can be useful if you need quickly a VM or instance group answering HTTPS for prototyping.

The generated cloud config is rendered in the `cloud_config` output, and is meant to be used in instances or instance templates via the `user-data` metadata.

## Example

```hcl
module "cos-nginx-tls" {
  source = "./fabric/modules/cloud-config-container/nginx-tls"
}

module "vm-nginx-tls" {
  source     = "./fabric/modules/compute-vm"
  project_id = "my-project"
  zone       = "europe-west8-b"
  name       = "cos-nginx-tls"
  network_interfaces = [{
    network    = "default"
    subnetwork = "gce"
  }]
  metadata = {
    user-data              = module.cos-nginx-tls.cloud_config
    google-logging-enabled = true
  }
  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
  tags = ["http-server", "https-server", "ssh"]
}
# tftest modules=1 resources=1
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [files](variables.tf#L17) | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <code title="map&#40;object&#40;&#123;&#10;  content     &#61; string&#10;  owner       &#61; optional&#40;string, &#34;root&#34;&#41;&#10;  permissions &#61; optional&#40;string, &#34;0644&#34;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [hello](variables.tf#L28) | Behave like the nginx hello image by returning plain text informative responses. | <code>bool</code> |  | <code>true</code> |
| [image](variables.tf#L35) | Nginx container image to use. | <code>string</code> |  | <code>&#34;nginx:1.23.1&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |

<!-- END TFDOC -->
