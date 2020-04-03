# Google KMS Module

Simple Cloud KMS module that allows managing a keyring, zero or more keys in the keyring, and IAM role bindings on individual keys.

The `protected` flag in the `key_attributes` variable sets the `prevent_destroy` lifecycle argument on an a per-key basis.

## Examples

### Minimal example

```hcl
module "kms" {
  source     = "../modules/kms"
  project_id = "my-project"
  keyring    = "test"
  location   = "europe"
  keys       = ["key-a", "key-b"]
}
```

### Granting access to keys via IAM

```hcl
module "kms" {
  source     = "../modules/kms"
  project_id = "my-project"
  keyring    = "test"
  location   = "europe"
  keys       = ["key-a", "key-b"]
  iam_roles = {
    key-a = ["roles/cloudkms.cryptoKeyDecrypter"]
  }
  iam_members = {
    key-a = {
      "roles/cloudkms.cryptoKeyDecrypter" = ["user:me@example.org"]
    }
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| keyring | Keyring name. | <code title="">string</code> | ✓ |  |
| location | Location for the keyring. | <code title="">string</code> | ✓ |  |
| project_id | Project id where the keyring will be created. | <code title="">string</code> | ✓ |  |
| *iam_members* | IAM members keyed by key name and role. | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *iam_roles* | IAM roles keyed by key name. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *key_attributes* | Optional key attributes per key. | <code title="map&#40;object&#40;&#123;&#10;protected       &#61; bool&#10;rotation_period &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *key_defaults* | Key attribute defaults. | <code title="object&#40;&#123;&#10;protected       &#61; bool&#10;rotation_period &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;protected       &#61; true&#10;rotation_period &#61; &#34;100000s&#34;&#10;&#125;">...</code> |
| *keys* | Key names. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| key_self_links | Key self links. |  |
| keyring | Keyring resource. |  |
| keys | Key resources. |  |
| location | Keyring self link. |  |
| name | Keyring self link. |  |
| self_link | Keyring self link. |  |
<!-- END TFDOC -->

## Requirements

These sections describe requirements for using this module.

### IAM

The following roles must be used to provision the resources of this module:

- Cloud KMS Admin: `roles/cloudkms.admin` or
- Owner: `roles/owner`

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- Google Cloud Key Management Service: `cloudkms.googleapis.com`
