# Google KMS Module

This module allows creating and managing KMS crypto keys and IAM bindings at both the keyring and crypto key level. An existing keyring can be used, or a new one can be created and managed by the module if needed.

When using an existing keyring be mindful about applying IAM bindings, as all bindings used by this module are authoritative, and you might inadvertently override bindings managed by the keyring creator.

<!-- BEGIN TOC -->
- [Protecting against destroy](#protecting-against-destroy)
- [Examples](#examples)
  - [Keyring creation and crypto key rotation and IAM roles](#keyring-creation-and-crypto-key-rotation-and-iam-roles)
  - [Using an existing keyring](#using-an-existing-keyring)
  - [Crypto key purpose](#crypto-key-purpose)
  - [Import job](#import-job)
  - [Tag Bindings](#tag-bindings)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Protecting against destroy

In this module **no lifecycle blocks are set on resources to prevent destroy**, in order to allow for experimentation and testing where rapid `apply`/`destroy` cycles are needed. If you plan on using this module to manage non-development resources, **clone it and uncomment the lifecycle blocks** found in `main.tf`.

## Examples

### Keyring creation and crypto key rotation and IAM roles

```hcl
module "kms" {
  source     = "./fabric/modules/kms"
  project_id = var.project_id
  keyring = {
    location = var.region
    name     = "test-1"
  }
  keys = {
    key-a = {
      iam = {
        "roles/cloudkms.admin" = ["group:${var.group_email}"]
      }
    }
    key-b = {
      rotation_period = "604800s"
      iam_bindings_additive = {
        key-b-iam1 = {
          key    = "key-b"
          member = "group:${var.group_email}"
          role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
        }
      }
    }
    key-c = {
      labels = {
        env = "test"
      }
    }
  }
}
# tftest modules=1 resources=6 inventory=basic.yaml e2e
```

### Using an existing keyring

```hcl
module "kms" {
  source     = "./fabric/modules/kms"
  project_id = var.project_id
  iam = {
    "roles/cloudkms.admin" = ["group:${var.group_email}"]
  }
  keyring        = { location = var.region, name = var.keyring.name }
  keyring_create = false
  keys           = { key-a = {}, key-b = {}, key-c = {} }
}
# tftest skip (uses data sources)
```

### Crypto key purpose

```hcl
module "kms" {
  source     = "./fabric/modules/kms"
  project_id = var.project_id
  keyring = {
    location = var.region
    name     = "test-2"
  }
  keys = {
    key-a = {
      purpose = "ASYMMETRIC_SIGN"
      version_template = {
        algorithm        = "EC_SIGN_P384_SHA384"
        protection_level = "HSM"
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=purpose.yaml e2e
```

### Import job

```hcl
module "kms" {
  source     = "./fabric/modules/kms"
  project_id = var.project_id
  keyring = {
    location = var.region
    name     = "test-3"
  }
  import_job = {
    id               = "my-import-job"
    import_method    = "RSA_OAEP_3072_SHA1_AES_256"
    protection_level = "SOFTWARE"
  }
}
# tftest modules=1 resources=2 inventory=import-job.yaml e2e
```

### Tag Bindings

Refer to the [Creating and managing tags](https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing) documentation for details on usage.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  tags = {
    environment = {
      description = "Environment specification."
      values = {
        dev     = {}
        prod    = {}
        sandbox = {}
      }
    }
  }
}

module "kms" {
  source     = "./fabric/modules/kms"
  project_id = var.project_id
  keyring = {
    location = var.region
    name     = "test-3"
  }
  tag_bindings = {
    env-sandbox = module.org.tag_values["environment/sandbox"].id
  }
}
# tftest modules=2 resources=6
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [keyring](variables.tf#L64) | Keyring attributes. | <code title="object&#40;&#123;&#10;  location &#61; string&#10;  name     &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L114) | Project id where the keyring will be created. | <code>string</code> | ✓ |  |
| [iam](variables.tf#L17) | Keyring IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L39) | Keyring individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [import_job](variables.tf#L54) | Keyring import job attributes. | <code title="object&#40;&#123;&#10;  id               &#61; string&#10;  import_method    &#61; string&#10;  protection_level &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [keyring_create](variables.tf#L72) | Set to false to manage keys and IAM bindings in an existing keyring. | <code>bool</code> |  | <code>true</code> |
| [keys](variables.tf#L78) | Key names and base attributes. Set attributes to null if not needed. | <code title="map&#40;object&#40;&#123;&#10;  destroy_scheduled_duration    &#61; optional&#40;string&#41;&#10;  rotation_period               &#61; optional&#40;string&#41;&#10;  labels                        &#61; optional&#40;map&#40;string&#41;&#41;&#10;  purpose                       &#61; optional&#40;string, &#34;ENCRYPT_DECRYPT&#34;&#41;&#10;  skip_initial_version_creation &#61; optional&#40;bool, false&#41;&#10;  version_template &#61; optional&#40;object&#40;&#123;&#10;    algorithm        &#61; string&#10;    protection_level &#61; optional&#40;string, &#34;SOFTWARE&#34;&#41;&#10;  &#125;&#41;&#41;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [tag_bindings](variables.tf#L119) | Tag bindings for this keyring, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified keyring id. |  |
| [import_job](outputs.tf#L30) | Keyring import job resources. |  |
| [key_ids](outputs.tf#L43) | Fully qualified key ids. |  |
| [keyring](outputs.tf#L56) | Keyring resource. |  |
| [keys](outputs.tf#L69) | Key resources. |  |
| [location](outputs.tf#L82) | Keyring location. |  |
| [name](outputs.tf#L95) | Keyring name. |  |
<!-- END TFDOC -->
