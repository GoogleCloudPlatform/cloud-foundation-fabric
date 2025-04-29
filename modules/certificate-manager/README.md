# Certificate manager

This module allows you to create a certificate manager map and associated entries, certificates, DNS authorizations and issueance configs. Map and associated entries creation is optional.

<!-- BEGIN TOC -->
- [Self-managed certificate](#self-managed-certificate)
- [Certificate map with 1 entry with 1 self-managed certificate](#certificate-map-with-1-entry-with-1-self-managed-certificate)
- [Certificate map with 1 entry with 1 managed certificate with load balancer authorization](#certificate-map-with-1-entry-with-1-managed-certificate-with-load-balancer-authorization)
- [Certificate map with 1 entry with 1 managed certificate with DNS authorization](#certificate-map-with-1-entry-with-1-managed-certificate-with-dns-authorization)
- [Certificate map with 1 entry with 1 managed certificate with issued by a CA Service instance](#certificate-map-with-1-entry-with-1-managed-certificate-with-issued-by-a-ca-service-instance)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Self-managed certificate

```hcl
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.private_key.private_key_pem
  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }
  validity_period_hours = 720
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

module "certificate-manager" {
  source     = "./fabric/modules/certificate-manager"
  project_id = var.project_id
  certificates = {
    my-certificate-1 = {
      self_managed = {
        pem_certificate = tls_self_signed_cert.cert.cert_pem
        pem_private_key = tls_private_key.private_key.private_key_pem
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=self-managed-cert.yaml
```

## Certificate map with 1 entry with 1 self-managed certificate

```hcl
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.private_key.private_key_pem
  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }
  validity_period_hours = 720
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

module "certificate-manager" {
  source     = "./fabric/modules/certificate-manager"
  project_id = var.project_id
  map = {
    name        = "my-certificate-map"
    description = "My certificate map"
    entries = {
      mydomain-mycompany-org = {
        certificates = [
          "my-certificate-1"
        ]
        hostname = "mydomain.mycompany.org"
      }
    }
  }
  certificates = {
    my-certificate-1 = {
      self_managed = {
        pem_certificate = tls_self_signed_cert.cert.cert_pem
        pem_private_key = tls_private_key.private_key.private_key_pem
      }
    }
  }
}
# tftest modules=1 resources=5 inventory=map-with-self-managed-cert.yaml

```

## Certificate map with 1 entry with 1 managed certificate with load balancer authorization

```hcl
module "certificate-manager" {
  source     = "./fabric/modules/certificate-manager"
  project_id = var.project_id
  map = {
    name        = "my-certificate-map"
    description = "My certificate map"
    entries = {
      mydomain-mycompany-org = {
        certificates = [
          "my-certificate-1"
        ]
        matcher = "PRIMARY"
      }
    }
  }
  certificates = {
    my-certificate-1 = {
      managed = {
        domains = ["mydomain.mycompany.org"]
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=map-with-managed-cert-lb-authz.yaml
```

## Certificate map with 1 entry with 1 managed certificate with DNS authorization

```hcl
module "certificate-manager" {
  source     = "./fabric/modules/certificate-manager"
  project_id = var.project_id
  map = {
    name        = "my-certificate-map"
    description = "My certificate map"
    entries = {
      mydomain-mycompany-org = {
        certificates = [
          "my-certificate-1"
        ]
        matcher = "PRIMARY"
      }
    }
  }
  certificates = {
    my-certificate-1 = {
      managed = {
        domains            = ["mydomain.mycompany.org"]
        dns_authorizations = ["mydomain-mycompany-org"]
      }
    }
  }
  dns_authorizations = {
    mydomain-mycompany-org = {
      type   = "PER_PROJECT_RECORD"
      domain = "mydomain.mycompany.org"
    }
  }
}
# tftest modules=1 resources=4 inventory=map-with-managed-cert-dns-authz.yaml
```

## Certificate map with 1 entry with 1 managed certificate with issued by a CA Service instance

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
    root_ca = {
      subject = {
        common_name  = "example.com"
        organization = "Example"
      }
      subject_alt_name = {
        dns_names = ["example.com"]
      }
    }
  }
}

module "certificate-manager" {
  source     = "./fabric/modules/certificate-manager"
  project_id = var.project_id
  map = {
    name        = "my-certificate-map"
    description = "My certificate map"
    entries = {
      cert-0 = {
        certificates = ["cert-0"]
        matcher      = "PRIMARY"
      }
    }
  }
  certificates = {
    cert-0 = {
      managed = {
        domains         = ["cert-0.example.com"]
        issuance_config = "config-0"
      }
    }
  }
  issuance_configs = {
    config-0 = {
      ca_pool                    = module.cas.ca_pool_id
      key_algorithm              = "ECDSA_P256"
      lifetime                   = "1814400s"
      rotation_window_percentage = 34
    }
  }
}
# tftest modules=2 resources=6 inventory=map-with-managed-cert-ca-service.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L113) | Project id. | <code>string</code> | ✓ |  |
| [certificates](variables.tf#L17) | Certificates. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string&#41;&#10;  labels      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  location    &#61; optional&#40;string&#41;&#10;  scope       &#61; optional&#40;string&#41;&#10;  self_managed &#61; optional&#40;object&#40;&#123;&#10;    pem_certificate &#61; string&#10;    pem_private_key &#61; string&#10;  &#125;&#41;&#41;&#10;  managed &#61; optional&#40;object&#40;&#123;&#10;    domains            &#61; list&#40;string&#41;&#10;    dns_authorizations &#61; optional&#40;list&#40;string&#41;&#41;&#10;    issuance_config    &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [dns_authorizations](variables.tf#L63) | DNS authorizations. | <code title="map&#40;object&#40;&#123;&#10;  domain      &#61; string&#10;  description &#61; optional&#40;string&#41;&#10;  location    &#61; optional&#40;string&#41;&#10;  type        &#61; optional&#40;string&#41;&#10;  labels      &#61; optional&#40;map&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [issuance_configs](variables.tf#L76) | Issuance configs. | <code title="map&#40;object&#40;&#123;&#10;  ca_pool                    &#61; string&#10;  description                &#61; optional&#40;string&#41;&#10;  key_algorithm              &#61; string&#10;  labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  lifetime                   &#61; string&#10;  location                   &#61; optional&#40;string&#41;&#10;  rotation_window_percentage &#61; number&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [map](variables.tf#L91) | Map attributes. | <code title="object&#40;&#123;&#10;  name        &#61; string&#10;  description &#61; optional&#40;string&#41;&#10;  labels      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  entries &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description  &#61; optional&#40;string&#41;&#10;    hostname     &#61; optional&#40;string&#41;&#10;    labels       &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    matcher      &#61; optional&#40;string&#41;&#10;    certificates &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [certificate_ids](outputs.tf#L17) | Certificate ids. |  |
| [certificates](outputs.tf#L22) | Certificates. |  |
| [dns_authorizations](outputs.tf#L27) | DNS authorizations. |  |
| [map](outputs.tf#L32) | Map. |  |
| [map_id](outputs.tf#L37) | Map id. |  |
<!-- END TFDOC -->
