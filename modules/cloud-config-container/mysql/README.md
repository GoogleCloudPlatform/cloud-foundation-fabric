# Containerized MySQL on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized [MySQL](https://www.mysql.com/) service on Container Optimized OS, using the [official image](https://hub.docker.com/_/mysql).

The resulting `cloud-config` can be customized in a number of ways:

- a custom MySQL configuration can be set using the `mysql_config` variable
- the container image can be changed via the `image` variable
- a data disk can be specified via the `mysql_data_disk` variable, the configuration will optionally format and mount it for container use
- a KMS encrypted root password can be passed to the container image, and decrypted at runtime on the instance using the attributes in the `kms_config` variable
- a completely custom `cloud-config` can be passed in via the `cloud_config` variable, and additional template variables can be passed in via `config_variables`

The default instance configuration inserts a sngle iptables rule to allow traffic on the default MySQL port.

Logging and monitoring are enabled via the [Google Cloud Logging agent](https://cloud.google.com/container-optimized-os/docs/how-to/logging) configured for the instance via the `google-logging-enabled` metadata property, and the [Node Problem Detector](https://cloud.google.com/container-optimized-os/docs/how-to/monitoring) service started by default on boot.

The module renders the generated cloud config in the `cloud_config` output, to be used in instances or instance templates via the `user-data` metadata.

For convenience during development or for simple use cases, the module can optionally manage a single instance via the `test_instance` variable. Please note that an `f1-micro` instance is too small to run MySQL. If the instance is not needed the `instance*tf` files can be safely removed. Refer to the [top-level README](../README.md) for more details on the included instance.

## Examples

### Default MySQL configuration

This example will create a `cloud-config` that uses the container's default configuration, and a plaintext password for the MySQL root user.

```hcl
module "cos-mysql" {
  source         = "./fabric/modules/cloud-config-container/mysql"
  mysql_password = "foo"
}

module "vm" {
  source     = "./fabric/modules/compute-vm"
  project_id = "my-project"
  zone       = "europe-west8-b"
  name       = "cos-mysql"
  network_interfaces = [{
    network    = "default"
    subnetwork = "gce"
  }]
  metadata = {
    user-data              = module.cos-mysql.cloud_config
    google-logging-enabled = true
  }
  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
  tags = ["mysql", "ssh"]
}
# tftest modules=1 resources=1
```

### Custom MySQL configuration and KMS encrypted password

This example will create a `cloud-config` that uses a custom MySQL configuration, and passes in an encrypted password and the KMS attributes required to decrypt it. Please note that the instance service account needs the `roles/cloudkms.cryptoKeyDecrypter` on the specified KMS key.

```hcl
module "cos-mysql" {
  source         = "./fabric/modules/cloud-config-container/mysql"
  mysql_config   = "./my.cnf"
  mysql_password = "CiQAsd7WY=="
  kms_config     = {
    project_id = "my-project"
    keyring    = "test-cos"
    location   = "europe-west1"
    key        = "mysql"
  }
}
# tftest modules=0 resources=0
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [mysql_password](variables.tf#L58) | MySQL root password. If an encrypted password is set, use the kms_config variable to specify KMS configuration. | <code>string</code> | ✓ |  |
| [cloud_config](variables.tf#L17) | Cloud config template path. If null default will be used. | <code>string</code> |  | <code>null</code> |
| [config_variables](variables.tf#L23) | Additional variables used to render the cloud-config template. | <code>map&#40;any&#41;</code> |  | <code>&#123;&#125;</code> |
| [image](variables.tf#L29) | MySQL container image. | <code>string</code> |  | <code>&#34;mysql:5.7&#34;</code> |
| [kms_config](variables.tf#L35) | Optional KMS configuration to decrypt passed-in password. Leave null if a plaintext password is used. | <code title="object&#40;&#123;&#10;  project_id &#61; string&#10;  keyring    &#61; string&#10;  location   &#61; string&#10;  key        &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [mysql_config](variables.tf#L46) | MySQL configuration file content, if null container default will be used. | <code>string</code> |  | <code>null</code> |
| [mysql_data_disk](variables.tf#L52) | MySQL data disk name in /dev/disk/by-id/ including the google- prefix. If null the boot disk will be used for data. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |

<!-- END TFDOC -->
