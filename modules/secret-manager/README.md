# Google Secret Manager

This module allows managing one or more secrets with versions and IAM bindings. For global secrets, this module optionally supports [write-only attributes](https://developer.hashicorp.com/terraform/language/manage-sensitive-data/write-only) for versions, which do not save data in state. Write-only attributes are not yet supported in OpenTofu, so this module is only compatible with Terraform until [OpenTofu support](https://github.com/opentofu/opentofu/issues/2834) has been released.

<!-- BEGIN TOC -->
- [Global Secrets](#global-secrets)
- [Regional Secrets](#regional-secrets)
- [IAM Bindings](#iam-bindings)
- [Secret Versions](#secret-versions)
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
# tftest modules=1 resources=4 inventory=secret.yaml skip-tofu
```

## Regional Secrets

Regional secrets are identified by having the `location` attribute defined, and share the same interface with a few exceptions: the `global_replica_locations` is of course ignored, and versions only support a subset of attributes and can't use write-only attributes.

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
# tftest modules=1 resources=2 inventory=secret-regional.yaml skip-tofu
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
# tftest modules=1 resources=4 inventory=iam.yaml skip-tofu
```

## Secret Versions

Versions are defined per secret via the `versions` attribute, and by default they accept string data which is stored in state. The `data_config` attributes allow configuring each secret:

- `data_config.is_file` instructs the module to read version data from a file (`data` is then used as the file path)
- `data_config.is_base64` instructs the provider to treat data as Base64
- `data_config.write_only_version` instructs the module to **use write-only attributes so that data is not set in state**, each time the write-only version is changed data is reuploaded to the secret version

As mentioned before write-only attributes are only available for global secrets. Regional secrets still use the potentially insecure way of storing data.

```hcl
module "secret-manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = var.project_id
  secrets = {
    test = {
      versions = {
        a = {
          # potentially unsafe
          data = "foo"
        }
        b = {
          # potentially unsafe, reads from file
          data = "test-data/secret-b.txt"
          data_config = {
            is_file = true
          }
        }
        c = {
          # uses safer write-only attribute
          data = "bar"
          data_config = {
            # bump this version when data needs updating
            write_only_version = 1
          }
        }
      }
    }
  }
}
# tftest files=0 modules=1 resources=4 inventory=versions.yaml skip-tofu
```

```txt
foo-secret
# tftest-file id=0 path=test-data/secret-b.txt
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
# tftest modules=1 resources=2 inventory=context.yaml skip-tofu
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L40) | Project id where the keyring will be created. | <code>string</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  condition_vars &#61; optional&#40;map&#40;map&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  custom_roles   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  kms_keys       &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_keys       &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_values     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [project_number](variables.tf#L45) | Project number of var.project_id. Set this to avoid permadiffs when creating tag bindings. | <code>string</code> |  | <code>null</code> |
| [secrets](variables.tf#L51) | Map of secrets to manage. Defaults to global secrets unless region is set. | <code title="map&#40;object&#40;&#123;&#10;  annotations              &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  deletion_protection      &#61; optional&#40;bool&#41;&#10;  kms_key                  &#61; optional&#40;string&#41;&#10;  labels                   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  global_replica_locations &#61; optional&#40;map&#40;string&#41;&#41;&#10;  location                 &#61; optional&#40;string&#41;&#10;  tag_bindings             &#61; optional&#40;map&#40;string&#41;&#41;&#10;  tags                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  expiration_config &#61; optional&#40;object&#40;&#123;&#10;    time &#61; optional&#40;string&#41;&#10;    ttl  &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  version_config &#61; optional&#40;object&#40;&#123;&#10;    aliases     &#61; optional&#40;map&#40;number&#41;&#41;&#10;    destroy_ttl &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  versions &#61; optional&#40;map&#40;object&#40;&#123;&#10;    data            &#61; string&#10;    deletion_policy &#61; optional&#40;string&#41;&#10;    enabled         &#61; optional&#40;bool&#41;&#10;    data_config &#61; optional&#40;object&#40;&#123;&#10;      is_base64          &#61; optional&#40;bool, false&#41;&#10;      is_file            &#61; optional&#40;bool, false&#41;&#10;      write_only_version &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

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
