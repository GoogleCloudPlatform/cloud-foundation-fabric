# Certificate Authority Service (CAS)

The module allows you to create one or more CAs and an optional CA pool.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Basic CA infrastructure](#basic-ca-infrastructure)
  - [Create custom CAs](#create-custom-cas)
  - [Reference an existing CA pool](#reference-an-existing-ca-pool)
  - [IAM](#iam)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

### Basic CA infrastructure

This is enough to create a test CA pool and a self-signed root CA.

```hcl
module "cas" {
  source     = "./fabric/modules/certificate-authority-service"
  project_id = var.project_id
  location   = "europe-west1"
  ca_pool_config = {
    create_pool = {
      name = "test-ca"
    }
  }
}
# tftest modules=1 resources=2 inventory=basic.yaml
```

### Create custom CAs

You can create multiple, custom CAs.

```hcl
module "cas" {
  source     = "./fabric/modules/certificate-authority-service"
  project_id = var.project_id
  location   = "europe-west1"
  ca_pool_config = {
    create_pool = {
      name = "test-ca"
    }
  }
  ca_configs = {
    root_ca_1 = {
      key_usage = {
        client_auth = true
        server_auth = true
      }
    }
    root_ca_2 = {
      subject = {
        common_name  = "test2.example.com"
        organization = "Example"
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=custom_cas.yaml
```

### Reference an existing CA pool

```hcl
module "cas" {
  source     = "./fabric/modules/certificate-authority-service"
  project_id = var.project_id
  location   = "europe-west1"
  ca_pool_config = {
    use_pool = {
      id = var.ca_pool_id
    }
  }
}
# tftest modules=1 resources=1 inventory=existing_ca.yaml
```

### IAM

You can assign authoritative and addittive IAM roles to identities on the CA pool, using the usual fabric interface (`iam`, `iam_bindings`, `iam_binding_addittive`, `iam_by_principals`).

```hcl
module "cas" {
  source     = "./fabric/modules/certificate-authority-service"
  project_id = var.project_id
  location   = "europe-west1"
  ca_pool_config = {
    create_pool = {
      name = "test-ca"
    }
  }
  iam = {
    "roles/privateca.certificateManager" = [
      var.service_account.iam_email
    ]
  }
  iam_bindings_additive = {
    cert-manager = {
      member = "group:${var.group_email}"
      role   = "roles/privateca.certificateManager"
    }
  }
}
# tftest modules=1 resources=4 inventory=iam.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [ca_pool_config](variables.tf#L105) | The CA pool config. Either use_pool or create_pool need to be used. Use pool takes precedence if both are defined. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [location](variables.tf#L134) | The location of the CAs. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L139) | Project id. | <code>string</code> | ✓ |  |
| [ca_configs](variables.tf#L17) | The CA configurations. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [context](variables.tf#L119) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables-iam.tf#L17) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L39) | Individual additive IAM bindings. Keys are arbitrary. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L54) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [ca_chains](outputs.tf#L17) | The CA chains in PEM format. |  |
| [ca_ids](outputs.tf#L25) | The CA ids. |  |
| [ca_pool](outputs.tf#L33) | The CA pool. |  |
| [ca_pool_id](outputs.tf#L38) | The CA pool id. |  |
| [cas](outputs.tf#L43) | The CAs. |  |
<!-- END TFDOC -->
