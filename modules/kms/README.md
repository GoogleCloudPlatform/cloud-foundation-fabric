# Google KMS Module

Simple Cloud KMS module that allows managing a keyring, zero or more keys in the keyring, and IAM role bindings on individual keys.

The resources/services/activations/deletions that this module will create/trigger are:

- Create a KMS keyring in the provided project
- Create zero or more keys in the keyring
- Create IAM role bindings for owners, encrypters, decrypters

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| keyring | Keyring name. | `string` | ✓
| location | Location for the keyring. | `string` | ✓
| project_id | Project id where the keyring will be created. | `string` | ✓
| *iam_members* | List of IAM members keyed by name and role. | `map(map(list(string)))` | 
| *iam_roles* | List of IAM roles keyed by name. | `map(list(string))` | 
| *key_attributes* | Optional key attributes per key. | `map(object({...}))` | 
| *key_defaults* | Key attribute defaults. | `object({...})` | 
| *keys* | Key names. | `list(string)` | 

## Outputs

| name | description | sensitive |
|---|---|:---:|
| key_self_links | Key self links. |  |
| keyring | Keyring resource. |  |
| keys | Key resources. |  |
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
