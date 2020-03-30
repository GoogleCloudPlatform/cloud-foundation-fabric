# Containerized MySQL on Container Optimized OS

- [ ] test module
- [ ] add description and examples

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| mysql_password | MySQL root password. If an encrypted password is set, use the kms_config variable to specify KMS configuration. | <code title="">string</code> | ✓ |  |
| *attached_disks* | Map of attached disks, key is the device path (eg /dev/disk/by-id/google-foo). Mount name is relative to /mnt/disks. Filesystem defaults to ext4 if null. | <code title="map&#40;object&#40;&#123;&#10;mount_name &#61; string&#10;filesystem &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *cloud_config* | Cloud config template path. If null default will be used. | <code title="">string</code> |  | <code title="">null</code> |
| *config_variables* | Additional variables used to render the cloud-config template. | <code title="map&#40;any&#41;">map(any)</code> |  | <code title="">{}</code> |
| *image* | MySQL container image. | <code title="">string</code> |  | <code title="">mysql:5.7</code> |
| *kms_config* | Optional KMS configuration to decrypt passed-in password. Leave null if a plaintext password is used. | <code title="object&#40;&#123;&#10;project_id &#61; string&#10;keyring    &#61; string&#10;location   &#61; string&#10;key        &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *mysql_config* | MySQL configuration file content, if null default will be used. | <code title="">string</code> |  | <code title="">null</code> |
| *test_instance* | Test/development instance attributes, leave null to skip creation. | <code title="object&#40;&#123;&#10;project_id &#61; string&#10;zone       &#61; string&#10;name       &#61; string&#10;type &#61; string&#10;tags       &#61; list&#40;string&#41;&#10;metadata   &#61; map&#40;string&#41;&#10;network    &#61; string&#10;subnetwork &#61; string&#10;disks &#61; list&#40;object&#40;&#123;&#10;device_name &#61; string&#10;mode        &#61; string&#10;source      &#61; string&#10;&#125;&#41;&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| cloud_config | Rendered cloud-config file to be passed as user-data instance metadata. |  |
| test_instance | Optional test instance name and address |  |
<!-- END TFDOC -->