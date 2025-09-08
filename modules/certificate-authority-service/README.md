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
| [ca_pool_config](variables.tf#L105) | The CA pool config. Either use_pool or create_pool need to be used. Use pool takes precedence if both are defined. | <code title="object&#40;&#123;&#10;  create_pool &#61; optional&#40;object&#40;&#123;&#10;    name            &#61; string&#10;    enterprise_tier &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  use_pool &#61; optional&#40;object&#40;&#123;&#10;    id &#61; string&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [location](variables.tf#L134) | The location of the CAs. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L139) | Project id. | <code>string</code> | ✓ |  |
| [ca_configs](variables.tf#L17) | The CA configurations. | <code title="map&#40;object&#40;&#123;&#10;  deletion_protection                    &#61; optional&#40;bool, true&#41;&#10;  is_ca                                  &#61; optional&#40;bool, true&#41;&#10;  is_self_signed                         &#61; optional&#40;bool, true&#41;&#10;  lifetime                               &#61; optional&#40;string, null&#41;&#10;  pem_ca_certificate                     &#61; optional&#40;string, null&#41;&#10;  ignore_active_certificates_on_deletion &#61; optional&#40;bool, false&#41;&#10;  skip_grace_period                      &#61; optional&#40;bool, true&#41;&#10;  labels                                 &#61; optional&#40;map&#40;string&#41;, null&#41;&#10;  gcs_bucket                             &#61; optional&#40;string, null&#41;&#10;  key_spec &#61; optional&#40;object&#40;&#123;&#10;    algorithm  &#61; optional&#40;string, &#34;RSA_PKCS1_2048_SHA256&#34;&#41;&#10;    kms_key_id &#61; optional&#40;string, null&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  key_usage &#61; optional&#40;object&#40;&#123;&#10;    cert_sign          &#61; optional&#40;bool, true&#41;&#10;    client_auth        &#61; optional&#40;bool, false&#41;&#10;    code_signing       &#61; optional&#40;bool, false&#41;&#10;    content_commitment &#61; optional&#40;bool, false&#41;&#10;    crl_sign           &#61; optional&#40;bool, true&#41;&#10;    data_encipherment  &#61; optional&#40;bool, false&#41;&#10;    decipher_only      &#61; optional&#40;bool, false&#41;&#10;    digital_signature  &#61; optional&#40;bool, false&#41;&#10;    email_protection   &#61; optional&#40;bool, false&#41;&#10;    encipher_only      &#61; optional&#40;bool, false&#41;&#10;    key_agreement      &#61; optional&#40;bool, false&#41;&#10;    key_encipherment   &#61; optional&#40;bool, true&#41;&#10;    ocsp_signing       &#61; optional&#40;bool, false&#41;&#10;    server_auth        &#61; optional&#40;bool, true&#41;&#10;    time_stamping      &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  subject &#61; optional&#40;object&#40;&#123;&#10;    common_name         &#61; string&#10;    organization        &#61; string&#10;    country_code        &#61; optional&#40;string&#41;&#10;    locality            &#61; optional&#40;string&#41;&#10;    organizational_unit &#61; optional&#40;string&#41;&#10;    postal_code         &#61; optional&#40;string&#41;&#10;    province            &#61; optional&#40;string&#41;&#10;    street_address      &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#10;    common_name  &#61; &#34;test.example.com&#34;&#10;    organization &#61; &#34;Test Example&#34;&#10;  &#125;&#41;&#10;  subject_alt_name &#61; optional&#40;object&#40;&#123;&#10;    dns_names       &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    email_addresses &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    ip_addresses    &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    uris            &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;  &#125;&#41;&#41;&#10;  subordinate_config &#61; optional&#40;object&#40;&#123;&#10;    root_ca_id              &#61; optional&#40;string&#41;&#10;    pem_issuer_certificates &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  test-ca &#61; &#123;&#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [context](variables.tf#L119) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  condition_vars  &#61; optional&#40;map&#40;map&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  custom_roles    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  kms_keys        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals  &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations       &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  storage_buckets &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables-iam.tf#L17) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L39) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
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
