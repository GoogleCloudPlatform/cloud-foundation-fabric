# Containerized CoreDNS on Container Optimized OS

This module creates a cloud-config configuration, used to configure and start a containerized [CoreDNS](https://coredns.io/) service on Container Optimized OS, using the [official image](https://hub.docker.com/r/coredns/coredns/).

The CoreDNS configuration and additional files (used for zone or hosts files) can be set via variables. Rules are added to iptables to allow DNS on TCP and UDP, and HTTP for health checks configurable via the CoreDNS [health plugin](https://coredns.io/plugins/health/).

Logging and monitoring are enabled via the [Google Cloud Logging driver](https://docs.docker.com/config/containers/logging/gcplogs/) configured for the CoreDNS container, and the [Node Problem Detector](https://cloud.google.com/container-optimized-os/docs/how-to/monitoring) service started by default on boot.

The module outputs the rendered cloud config to be set in the `user-data` metadata of instances or instance templates. For convenience in test or development setups, a simple instance can be created and managed via the `test_instance` variable. Refer to the [top-level README](../README.md) for details on the instance configuration.

## Examples

### Default CoreDNS configuration

This example will create a cloud-config that uses the module's defaults. No variables are needed, the cloud-config is available from the module's outputs.

```hcl
module "cos-coredns" {
  source           = "./modules/cos-container/coredns"
}

# use it as metadata in a compute instance or template
resource "google_compute_instance" "default" {
  metadata = {
    user-data = module.cos-coredns.cloud_config
  }
```

### Custom CoreDNS configuration

This example will create a cloud-config that changes the CoreDNS configuration to use the [CoreDNS hosts plugin](), and adds a simple hosts-format file. Again, the cloud-config is available from the module's outputs.

```hcl
module "cos-coredns" {
  source           = "./modules/cos-container/coredns"
  coredns_config = "./modules/cos-container/coredns/Corefile-hosts"
  files = {
    "/etc/coredns/example.hosts" = {
      content     = "127.0.0.2 foo.example.org foo"
      owner       = null
      permissions = "0644"
    }
}
```

### Create the test instance

To create the test instance, simply set the appropriate values in the `test_instance` variable. An instance and a custom service account with logging and monitoring write permissions will be created.

```hcl
module "cos-coredns" {
  source           = "./modules/cos-container/coredns"
  test_instance = {
    project_id = "my-project"
    zone       = "europe-west1-b"
    name       = "cos-coredns"
    type       = "f1-micro"
    tags       = ["ssh"]
    metadata   = {}
    network    = "default"
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/my-subnet"
    disks      = []
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| *cloud_config* | Cloud config template path. If null default will be used. | <code title="">string</code> |  | <code title="">null</code> |
| *config_variables* | Additional variables used to render the cloud-config template. | <code title="map&#40;any&#41;">map(any)</code> |  | <code title="">{}</code> |
| *coredns_config* | CoreDNS configuration file content, if null default will be used. | <code title="">string</code> |  | <code title="">null</code> |
| *file_defaults* | Default owner and permissions for files. | <code title="object&#40;&#123;&#10;owner       &#61; string&#10;permissions &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;owner       &#61; &#34;root&#34;&#10;permissions &#61; &#34;0644&#34;&#10;&#125;">...</code> |
| *files* | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <code title="map&#40;object&#40;&#123;&#10;content     &#61; string&#10;owner       &#61; string&#10;permissions &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *test_instance* | Test/development instance attributes, leave null to skip creation. | <code title="object&#40;&#123;&#10;project_id &#61; string&#10;zone       &#61; string&#10;name       &#61; string&#10;type &#61; string&#10;tags       &#61; list&#40;string&#41;&#10;metadata   &#61; map&#40;string&#41;&#10;network    &#61; string&#10;subnetwork &#61; string&#10;disks &#61; list&#40;object&#40;&#123;&#10;device_name &#61; string&#10;mode        &#61; string&#10;source      &#61; string&#10;&#125;&#41;&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| cloud_config | Rendered cloud-config file to be passed as user-data instance metadata. |  |
| test_instance | Optional test instance name and address |  |
<!-- END TFDOC -->