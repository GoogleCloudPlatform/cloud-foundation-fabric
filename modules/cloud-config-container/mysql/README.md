# Containerized MySQL on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized [MySQL](https://www.mysql.com/) service on Container Optimized OS, using the [official image](https://hub.docker.com/_/mysql).

The resulting `cloud-config` can be customized in a number of ways:

- a custom MySQL configuration can be set using the `mysql_config` variable
- the container image can be changed via the `image` variable
- a data disk can be specified via the `mysql_data_disk` variable, the configuration will optionally format and mount it for container use
- a KMS encrypted root password can be passed to the container image, and decrypted at runtime on the instance using the attributes in the `kms_config` variable
- a completely custom `cloud-config` can be passed in via the `cloud_config` variable, and additional template variables can be passed in via `config_variables`

The default instance configuration inserts a sngle iptables rule to allow traffic on the default MySQL port.

Logging and monitoring are enabled via the [Google Cloud Logging driver](https://docs.docker.com/config/containers/logging/gcplogs/) configured for the CoreDNS container, and the [Node Problem Detector](https://cloud.google.com/container-optimized-os/docs/how-to/monitoring) service started by default on boot.

The module renders the generated cloud config in the `cloud_config` output, to be used in instances or instance templates via the `user-data` metadata.

For convenience during development or for simple use cases, the module can optionally manage a single instance via the `test_instance` variable. Please note that an `f1-micro` instance is too small to run MySQL. If the instance is not needed the `instance*tf` files can be safely removed. Refer to the [top-level README](../README.md) for more details on the included instance.

## Examples

### Default MySQL configuration

This example will create a `cloud-config` that uses the container's default configuration, and a plaintext password for the MySQL root user.

```hcl
module "cos-mysql" {
  source         = "./modules/cos-container/mysql"
  mysql_password = "foo"
}

# use it as metadata in a compute instance or template
resource "google_compute_instance" "default" {
  metadata = {
    user-data = module.cos-mysql.cloud_config
  }
```

### Custom MySQL configuration and KMS encrypted password

This example will create a `cloud-config` that uses a custom MySQL configuration, and passes in an encrypted password and the KMS attributes required to decrypt it. Please note that the instance service account needs the `roles/cloudkms.cryptoKeyDecrypter` on the specified KMS key.

```hcl
module "cos-mysql" {
  source         = "./modules/cos-container/mysql"
  mysql_config   = "./my.cnf"
  mysql_password = "CiQAsd7WY=="
  kms_config     = {
    project_id = "my-project"
    keyring    = "test-cos"
    location   = "europe-west1"
    key        = "mysql"
  }
}
```

### MySQL instance

This example shows how to create the single instance optionally managed by the module, providing all required attributes in the `test_instance` variable. The instance is purposefully kept simple and should only be used in development, or when designing infrastructures.

```hcl
module "cos-mysql" {
  source         = "./modules/cos-container/mysql"
  mysql_password = "foo"
  test_instance = {
    project_id = "my-project"
    zone       = "europe-west1-b"
    name       = "cos-mysql"
    type       = "n1-standard-1"
    network    = "default"
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/my-subnet"
  }
}
```

<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| mysql_password | MySQL root password. If an encrypted password is set, use the kms_config variable to specify KMS configuration. | <code>string</code> | ✓ |  |
| cloud_config | Cloud config template path. If null default will be used. | <code>string</code> |  | <code>&#34;null&#34;</code> |
| config_variables | Additional variables used to render the cloud-config template. | <code>map&#40;any&#41;</code> |  | <code>&#123;&#125;</code> |
| image | MySQL container image. | <code>string</code> |  | <code>&#34;mysql:5.7&#34;</code> |
| kms_config | Optional KMS configuration to decrypt passed-in password. Leave null if a plaintext password is used. | <code title="object&#40;&#123;&#10;  project_id &#61; string&#10;  keyring    &#61; string&#10;  location   &#61; string&#10;  key        &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| mysql_config | MySQL configuration file content, if null container default will be used. | <code>string</code> |  | <code>&#34;null&#34;</code> |
| mysql_data_disk | MySQL data disk name in /dev/disk/by-id/ including the google- prefix. If null the boot disk will be used for data. | <code>string</code> |  | <code>&#34;null&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| cloud_config | Rendered cloud-config file to be passed as user-data instance metadata. |  |


<!-- END TFDOC -->
