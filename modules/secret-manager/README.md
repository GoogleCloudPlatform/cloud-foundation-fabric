# Google Secret Manager

This module allows managing one or more secrets with versions and IAM bindings. Version data can be passed via [write-only attributes](https://developer.hashicorp.com/terraform/language/manage-sensitive-data/write-only), which do not save data in state, for both global and regional secrets.

<!-- BEGIN TOC -->
- [Global Secrets](#global-secrets)
- [Regional Secrets](#regional-secrets)
- [IAM Bindings](#iam-bindings)
- [Secret Versions](#secret-versions)
- [Secret values](#secret-values)
- [Secret Rotation](#secret-rotation)
- [Context Interpolations](#context-interpolations)
- [Variables](#variables)
- [Outputs](#outputs)
- [Requirements](#requirements)
- [IAM](#iam)
- [APIs](#apis)
<!-- END TOC -->

## Global Secrets

Secrets are created as global by default, with auto replication policy. For auto managed replication secrets the `kms_key` attribute can be used to configure CMEK via a global key.

To configure a secret for user managed replication configure the `global_replica_locations` attribute. Non-auto secrets ignore the `kms_key` attribute, but use each element of the locations map to configure keys.

```hcl
module "secret-manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = var.project_id
  secrets = {
    test-auto = {}
    test-auto-cmek = {
      kms_key = "projects/test-0/locations/global/keyRings/test-g/cryptoKeys/sec"
    }
    test-user = {
      global_replica_locations = {
        europe-west1 = null
        europe-west3 = null
      }
    }
    test-user-cmek = {
      global_replica_locations = {
        europe-west1 = "projects/test-0/locations/europe-west1/keyRings/test-g/cryptoKeys/sec-ew1"
        europe-west3 = "projects/test-0/locations/europe-west3/keyRings/test-g/cryptoKeys/sec-ew3"
      }
    }
  }
}
# tftest modules=1 resources=4 inventory=secret.yaml
```

## Regional Secrets

Regional secrets are identified by having the `location` attribute defined, and share the same interface with a few exceptions: the `global_replica_locations` is of course ignored, and versions only support a subset of attributes.

```hcl
module "secret-manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = var.project_id
  secrets = {
    test = {
      location = "europe-west1"
    }
    test-cmek = {
      location = "europe-west1"
      kms_key  = "projects/test-0/locations/global/keyRings/test-g/cryptoKeys/sec"
    }
  }
}
# tftest modules=1 resources=2 inventory=secret-regional.yaml
```

## IAM Bindings

This module supports the same IAM interface as all other modules in this repository. IAM bindings are defined per secret, if you need cross-secret IAM bindings use project-level ones.

```hcl
module "secret-manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = var.project_id
  secrets = {
    test = {
      iam = {
        "roles/secretmanager.admin" = [
          "user:test-0@example.com"
        ]
      }
      iam_bindings = {
        test = {
          role = "roles/secretmanager.secretAccessor"
          members = [
            "user:test-1@example.com"
          ]
          condition = {
            title      = "Test."
            expression = "resource.matchTag('1234567890/environment', 'test')"
          }
        }
      }
      iam_bindings_additive = {
        test = {
          role   = "roles/secretmanager.viewer"
          member = "user:test-2@example.com"
        }
      }
    }
  }
}
# tftest modules=1 resources=4 inventory=iam.yaml
```

## Secret Versions

Versions are defined per secret via the `versions` attribute. Each version carries its secret in the `data` object, described in the [Secret values](#secret-values) section below, and an `is_base64` attribute which instructs the provider to treat data as Base64.

```hcl
module "secret-manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = var.project_id
  secrets = {
    test = {
      versions = {
        a = {
          # potentially unsafe, stored in state
          data = {
            value = "foo"
          }
        }
        b = {
          # potentially unsafe, reads from file and stores in state
          data = {
            path = "test-data/secret-b.txt"
          }
        }
        c = {
          # uses safer write-only attribute
          data = {
            value = "bar"
            # bump this version when data needs updating
            wo_version = 1
          }
        }
      }
    }
  }
}
# tftest files=0 modules=1 resources=4 inventory=versions.yaml
```

```txt
foo-secret
# tftest-file id=0 path=test-data/secret-b.txt
```

## Secret values

`versions.*.data` is an object that follows the [shape used for secrets across modules](../../adrs/modules/20261029-write-only-secrets.md):

- `value` is the secret itself
- `path` is the path to a file containing the secret, read via `file(pathexpand(path))` and relative to the root module; the file must exist at every plan
- `wo_version` switches to the provider's write-only attribute, so that the secret is never stored in state; bump the number whenever the secret changes and needs to be sent again

Only one of `value` and `path` can be set. Without `wo_version` the secret is stored in state, and that form should only be used when this is acceptable. With `wo_version` set, both `value` and `path` can be null once the secret has been applied, since the provider leaves the existing write-only value untouched until the version changes: this allows passing `value = try(file("secret.txt"), null)` and removing the file after the first apply.

## Secret Rotation

Automated rotation schedules and Pub/Sub notification topics can be configured on both global and regional secrets via `rotation_config` and `topics`. Note that the Secret Manager API requires at least one Pub/Sub topic when rotation is configured.

```hcl
module "secret-manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = var.project_id
  secrets = {
    test-rotated = {
      rotation_config = {
        period    = "7776000s" # 90 days
        next_time = "2026-12-01T00:00:00Z"
      }
      topics = [
        "projects/project-id/topics/secret-rotation-topic"
      ]
    }
  }
}
# tftest modules=1 resources=1
```

## Context Interpolations

Similarly to other core modules in this repository, this module also supports context-based interpolations, which are populated via the `context` variable.

This is a summary table of the available contexts, which can be used whenever an attribute expects the relevant information. Refer to the [project factory module](../project-factory/README.md#context-based-interpolation) for more details on context replacements.

- `$custom_roles:my_role`
- `$iam_principals:my_principal`
- `$kms_keys:my_key`
- `$locations:my_location`
- `$project_ids:my_project`
- `$tag_keys:my_key`
- `$tag_values:my_value`
- custom template variables used in IAM conditions

This is a simple example that uses context interpolation.

```hcl
module "secret-manager" {
  source = "./fabric/modules/secret-manager"
  context = {
    iam_principals = {
      mysa   = "serviceAccount:test@foo-prod-test-0.iam.gserviceaccount.com"
      myuser = "user:test@example.com"
    }
    kms_keys = {
      primary   = "projects/test-0/locations/europe-west1/keyRings/test-g/cryptoKeys/sec-ew1"
      secondary = "projects/test-0/locations/europe-west3/keyRings/test-g/cryptoKeys/sec-ew3"
    }
    locations = {
      primary   = "europe-west1"
      secondary = "europe-west3"
    }
    project_ids = {
      test = "foo-prod-test-0"
    }
  }
  project_id = "$project_ids:test"
  secrets = {
    test-user-cmek = {
      global_replica_locations = {
        "$locations:primary"   = "$kms_keys:primary"
        "$locations:secondary" = "$kms_keys:secondary"
      }
      iam = {
        "roles/secretmanager.viewer" = [
          "$iam_principals:mysa", "$iam_principals:myuser"
        ]
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=context.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L44) | Project id where the keyring will be created. | <code>string</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [project_number](variables.tf#L49) | Project number of var.project_id. Set this to avoid permadiffs when creating tag bindings. | <code>string</code> |  | <code>null</code> |
| [secrets](variables.tf#L55) | Map of secrets to manage. Defaults to global secrets unless region is set. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [ids](outputs.tf#L28) | Fully qualified secret ids. |  |
| [secrets](outputs.tf#L41) | Secret resources. |  |
| [version_ids](outputs.tf#L54) | Fully qualified version ids. |  |
| [version_versions](outputs.tf#L67) | Version versions. |  |
| [versions](outputs.tf#L80) | Version resources. | ✓ |
<!-- END TFDOC -->
## Requirements

These sections describe requirements for using this module.

## IAM

The following roles must be used to provision the resources of this module:

- Cloud KMS Admin: `roles/cloudkms.admin` or
- Owner: `roles/owner`

## APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- Google Cloud Key Management Service: `cloudkms.googleapis.com`
