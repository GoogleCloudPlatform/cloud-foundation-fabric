# Containerized Squid on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized [Squid](http://www.squid-cache.org/) proxy on Container Optimized OS. The default configuration creates a filtering proxy that only allows connection to a whitelisted set of domains.

The resulting `cloud-config` can be customized in a number of ways:

- a custom squid.conf configuration can be set using the `squid_config` variable
- additional files (e.g. additional acls) can be passed in via the `files` variable
- a completely custom `cloud-config` can be passed in via the `cloud_config` variable, and additional template variables can be passed in via `config_variables`

The default instance configuration inserts iptables rules to allow traffic on TCP port 3128.

Logging and monitoring are enabled via the [Google Cloud Logging driver](https://docs.docker.com/config/containers/logging/gcplogs/) configured for the Squid container, and the [Node Problem Detector](https://cloud.google.com/container-optimized-os/docs/how-to/monitoring) service started by default on boot.

The module renders the generated cloud config in the `cloud_config` output, to be used in instances or instance templates via the `user-data` metadata.

For convenience during development or for simple use cases, the module can optionally manage a single instance via the `test_instance` variable. If the instance is not needed the `instance*tf` files can be safely removed. Refer to the [top-level README](../README.md) for more details on the included instance.

## Examples

### Default Squid configuration

This example will create a `cloud-config` that allows any client in the 10.0.0.0/8 CIDR to use the proxy to connect github.com or any subdomain of github.com.

```hcl
module "cos-squid" {
  source           = "./modules/cos-container/squid"
  whitelist = [".github.com"]
  clients   = ["10.0.0.0/8"]
}

# use it as metadata in a compute instance or template
resource "google_compute_instance" "default" {
  metadata = {
    user-data = module.cos-squid.cloud_config
  }
```

### Test Squid instance

This example shows how to create the single instance optionally managed by the module, providing all required attributes in the `test_instance` variable. The instance is purposefully kept simple and should only be used in development, or when designing infrastructures.

```hcl
module "cos-squid" {
  source           = "./modules/cos-container/squid"
  whitelist = ["github.com"]
  clients   = ["10.0.0.0/8"]
  test_instance = {
    project_id = "my-project"
    zone       = "europe-west1-b"
    name       = "cos-squid"
    type       = "f1-micro"
    network    = "default"
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/my-subnet"
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| *clients* | List of CIDRs from which Squid will allow connections | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *cloud_config* | Cloud config template path. If null default will be used. | <code title="">string</code> |  | <code title="">null</code> |
| *config_variables* | Additional variables used to render the cloud-config and Squid templates. | <code title="map&#40;any&#41;">map(any)</code> |  | <code title="">{}</code> |
| *file_defaults* | Default owner and permissions for files. | <code title="object&#40;&#123;&#10;owner       &#61; string&#10;permissions &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;owner       &#61; &#34;root&#34;&#10;permissions &#61; &#34;0644&#34;&#10;&#125;">...</code> |
| *files* | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <code title="map&#40;object&#40;&#123;&#10;content     &#61; string&#10;owner       &#61; string&#10;permissions &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *squid_config* | Squid configuration path, if null default will be used. | <code title="">string</code> |  | <code title="">null</code> |
| *test_instance* | Test/development instance attributes, leave null to skip creation. | <code title="object&#40;&#123;&#10;project_id &#61; string&#10;zone       &#61; string&#10;name       &#61; string&#10;type &#61; string&#10;network    &#61; string&#10;subnetwork &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *test_instance_defaults* | Test/development instance defaults used for optional configuration. If image is null, COS stable will be used. | <code title="object&#40;&#123;&#10;disks &#61; map&#40;object&#40;&#123;&#10;read_only &#61; bool&#10;size      &#61; number&#10;&#125;&#41;&#41;&#10;image                 &#61; string&#10;metadata              &#61; map&#40;string&#41;&#10;nat                   &#61; bool&#10;service_account_roles &#61; list&#40;string&#41;&#10;tags                  &#61; list&#40;string&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;disks    &#61; &#123;&#125;&#10;image    &#61; null&#10;metadata &#61; &#123;&#125;&#10;nat      &#61; false&#10;service_account_roles &#61; &#91;&#10;&#34;roles&#47;logging.logWriter&#34;,&#10;&#34;roles&#47;monitoring.metricWriter&#34;&#10;&#93;&#10;tags &#61; &#91;&#34;ssh&#34;&#93;&#10;&#125;">...</code> |
| *whitelist* | List of domains Squid will allow connections to | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| cloud_config | Rendered cloud-config file to be passed as user-data instance metadata. |  |
| test_instance | Optional test instance name and address |  |
<!-- END TFDOC -->
