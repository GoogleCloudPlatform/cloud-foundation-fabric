# Google KMS Module

This module allows creating and managing KMS crypto keys and IAM bindings at both the keyring and crypto key level. An existing keyring can be used, or a new one can be created and managed by the module if needed.

When using an existing keyring be mindful about applying IAM bindings, as all bindings used by this module are authoritative, and you might inadvertently override bindings managed by the keyring creator.

## Protecting against destroy

In this module **no lifecycle blocks are set on resources to prevent destroy**, in order to allow for experimentation and testing where rapid `apply`/`destroy` cycles are needed. If you plan on using this module to manage non-development resources, **clone it and uncomment the lifecycle blocks** found in `main.tf`.

## Examples

### Using an existing keyring

```hcl
module "kms" {
  source         = "./modules/kms"
  project_id     = "my-project"
  iam    = {
    "roles/owner" = ["user:user1@example.com"]
  }
  keyring        = { location = "europe-west1", name = "test" }
  keyring_create = false
  keys           = { key-a = null, key-b = null, key-c = null }
}
# tftest:skip
```

### Keyring creation and crypto key rotation and IAM roles

```hcl
module "kms" {
  source     = "./modules/kms"
  project_id = "my-project"
  key_iam = {
    key-a = {
      "roles/owner" = ["user:user1@example.com"]
    }
  }
  keyring = { location = "europe-west1", name = "test" }
  keys = {
    key-a = null
    key-b = { rotation_period = "604800s", labels = null }
    key-c = { rotation_period = null, labels = { env = "test" } }
  }
}
# tftest:modules=1:resources=5
```

### Crypto key purpose

```hcl
module "kms" {
  source      = "./modules/kms"
  project_id  = "my-project"
  key_purpose = {
    key-c = {
      purpose = "ASYMMETRIC_SIGN"
      version_template = {
        algorithm        = "EC_SIGN_P384_SHA384"
        protection_level = null
      }
    }
  }
  keyring     = { location = "europe-west1", name = "test" }
  keys        = { key-a = null, key-b = null, key-c = null }
}
# tftest:modules=1:resources=4
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| keyring | Keyring attributes. | <code title="object&#40;&#123;&#10;location &#61; string&#10;name     &#61; string&#10;&#125;&#41;">object({...})</code> | ✓ |  |
| project_id | Project id where the keyring will be created. | <code title="">string</code> | ✓ |  |
| *iam* | Keyring IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *key_iam* | Key IAM bindings for topic in {KEY => {ROLE => [MEMBERS]}} format. | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *key_purpose* | Per-key purpose, if not set defaults will be used. If purpose is not `ENCRYPT_DECRYPT` (the default), `version_template.algorithm` is required. | <code title="map&#40;object&#40;&#123;&#10;purpose &#61; string&#10;version_template &#61; object&#40;&#123;&#10;algorithm        &#61; string&#10;protection_level &#61; string&#10;&#125;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *key_purpose_defaults* | Defaults used for key purpose when not defined at the key level. If purpose is not `ENCRYPT_DECRYPT` (the default), `version_template.algorithm` is required. | <code title="object&#40;&#123;&#10;purpose &#61; string&#10;version_template &#61; object&#40;&#123;&#10;algorithm        &#61; string&#10;protection_level &#61; string&#10;&#125;&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;purpose          &#61; null&#10;version_template &#61; null&#10;&#125;">...</code> |
| *keyring_create* | Set to false to manage keys and IAM bindings in an existing keyring. | <code title="">bool</code> |  | <code title="">true</code> |
| *keys* | Key names and base attributes. Set attributes to null if not needed. | <code title="map&#40;object&#40;&#123;&#10;rotation_period &#61; string&#10;labels          &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| key_self_links | Key self links. |  |
| keyring | Keyring resource. |  |
| keys | Key resources. |  |
| location | Keyring location. |  |
| name | Keyring name. |  |
| self_link | Keyring self link. |  |
<!-- END TFDOC -->
