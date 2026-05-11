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
    name     = "${var.prefix}-test"
  }
  keys = {
    key-a = {
      iam = {
        "roles/cloudkms.admin" = ["group:${var.group_email}"]
      }
      iam_bindings = {
        agent = {
          role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
          members = [var.service_account.iam_email]
        }
      }
    }
    key-b = {
      rotation_period = "604800s"
      iam_bindings = {
        # reusing the same binding name across different keys is supported
        agent = {
          role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
          members = [var.service_account.iam_email]
        }
      }
      iam_bindings_additive = {
        key-b-iam1 = {
          key    = "key-b"
          member = "group:${var.group_email}"
          role   = "roles/cloudkms.viewer"
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
# tftest modules=1 resources=8 inventory=basic.yaml e2e
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
    name     = "${var.prefix}-test"
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
    name     = "${var.prefix}-test"
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
    name     = "${var.prefix}-test"
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
| [keyring](variables.tf#L84) | Keyring attributes. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L153) | Project id where the keyring will be created. | <code>string</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L37) | Keyring IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L44) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L59) | Keyring individual additive IAM bindings. Keys are arbitrary. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [import_job](variables.tf#L74) | Keyring import job attributes. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [keyring_create](variables.tf#L93) | Set to false to manage keys and IAM bindings in an existing keyring. | <code>bool</code> |  | <code>true</code> |
| [keys](variables.tf#L99) | Key names and base attributes. Set attributes to null if not needed. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [tag_bindings](variables.tf#L158) | Tag bindings for this keyring, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |

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
