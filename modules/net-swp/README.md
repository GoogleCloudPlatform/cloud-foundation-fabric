# Google Cloud Secure Web Proxy

This module allows creation and management of [Secure Web Proxy](https://cloud.google.com/secure-web-proxy/docs/overview), and its URL lists and policy rules.

It also allows to deploy SWP as a Private Service Connect service.
This means that a single SWP deployment can be used from across different VPCs, regardless of whether they are interconnected.

A [Proxy-only subnet](https://cloud.google.com/load-balancing/docs/proxy-only-subnets) must exist in the VPC where SWP is deployed.

When deploying SWP, the required ad-hoc [Cloud Router](https://cloud.google.com/network-connectivity/docs/router) is also created.

<!-- BEGIN TOC -->
- [Minimal Secure Web Proxy](#minimal-secure-web-proxy)
- [PSC service attachments](#psc-service-attachments)
- [Secure Web Proxy with rules](#secure-web-proxy-with-rules)
- [Secure Web Proxy with TLS inspection](#secure-web-proxy-with-tls-inspection)
- [Secure Web Proxy as transparent proxy](#secure-web-proxy-as-transparent-proxy)
- [Factories](#factories)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Minimal Secure Web Proxy

(Note that this will not allow any request to pass.)

```hcl
module "secure-web-proxy" {
  source     = "./fabric/modules/net-swp"
  project_id = "my-project"
  region     = "europe-west4"
  name       = "secure-web-proxy"
  network    = "projects/my-project/global/networks/my-network"
  subnetwork = "projects/my-project/regions/europe-west4/subnetworks/my-subnetwork"
  certificates = [
    "projects/my-project/locations/europe-west4/certificates/secure-web-proxy-cert"
  ]
  gateway_config = {
    addresses = ["10.142.68.3"]
    labels = {
      example = "value"
    }
  }
}
# tftest modules=1 resources=2 inventory=basic.yaml
```

## PSC service attachments

The optional `service_attachment` variable allows [deploying SWP as a Private Service Connect service attachment](https://cloud.google.com/secure-web-proxy/docs/deploy-service-attachment)

```hcl
module "secure-web-proxy" {
  source     = "./fabric/modules/net-swp"
  project_id = "my-project"
  region     = "europe-west4"
  name       = "secure-web-proxy"
  network    = "projects/my-project/global/networks/my-network"
  subnetwork = "projects/my-project/regions/europe-west4/subnetworks/my-subnetwork"
  certificates = [
    "projects/my-project/locations/europe-west4/certificates/secure-web-proxy-cert"
  ]
  gateway_config = {
    addresses = ["10.142.68.3"]
    labels = {
      example = "value"
    }
  }
  service_attachment = {
    nat_subnets = ["projects/my-project/regions/europe-west4/subnetworks/my-psc-subnetwork"]
    consumer_accept_lists = {
      "my-autoaccept-project-1" = 1,
      "my-autoaccept-project-2" = 1
    }
  }
}
# tftest modules=1 resources=3 inventory=psc.yaml
```

## Secure Web Proxy with rules

This example shows different ways of defining policy rules, including how to leverage substitution for internally generated URL maps, or externally defined resources.

```hcl
module "secure-web-proxy" {
  source     = "./fabric/modules/net-swp"
  project_id = "my-project"
  region     = "europe-west4"
  name       = "secure-web-proxy"
  network    = "projects/my-project/global/networks/my-network"
  subnetwork = "projects/my-project/regions/europe-west4/subnetworks/my-subnetwork"
  certificates = [
    "projects/my-project/locations/europe-west4/certificates/secure-web-proxy-cert"
  ]
  gateway_config = {
    addresses = ["10.142.68.3"]
    ports     = [80, 443]
    labels = {
      example = "value"
    }
  }
  policy_rules = {
    host-0 = {
      priority        = 1000
      allow           = false
      session_matcher = "host() == 'google.com'"
    }
    secure-tag-0 = {
      priority        = 1001
      session_matcher = <<END
        source.matchTag('tagValues/281484836404786') && host() == 'example.com'
      END
    }
    secure-tag-1 = {
      priority        = 1002
      session_matcher = <<END
        source.matchTag('tagValues/281484836404786') && host() != 'google.com'
      END
    }
    service-account-0 = {
      priority        = 1003
      session_matcher = <<END
        source.matchServiceAccount('%s') && host() == 'example.com'
      END
      matcher_args = {
        session = ["service_account:foo"]
      }
    }
    url-list-0 = {
      priority        = 1004
      session_matcher = <<END
        inUrlList(
          host(),
          'projects/my-project/locations/europe-west4/urlLists/my-url-list'
        )
      END
    }
    url-list-1 = {
      priority        = 1005
      session_matcher = "inUrlList(host(), '%s')"
      matcher_args = {
        session = [
          "url_list:projects/my-project/locations/europe-west4/urlLists/default"
        ]
      }
    }
  }
  policy_rules_contexts = {
    service_accounts = {
      foo = "foo@my-prj.iam.gserviceaccount.com"
    }
  }
  url_lists = {
    default = {
      values = [
        "example.org"
      ]
    }
  }
}
# tftest modules=1 resources=9 inventory=rules.yaml
```

## Secure Web Proxy with TLS inspection

You can activate TLS inspection and let the module handle the TLS inspection policy creation.

```hcl

resource "google_privateca_ca_pool" "pool" {
  project  = "my-project"
  location = "europe-west4"
  name     = "swp"
  tier     = "DEVOPS"
}

resource "google_privateca_certificate_authority" "ca" {
  project                  = "my-project"
  location                 = "europe-west4"
  pool                     = google_privateca_ca_pool.pool.name
  certificate_authority_id = "swp"
  deletion_protection      = "false"
  lifetime                 = "1209600s"
  config {
    subject_config {
      subject {
        organization = "Cloud Foundation Fabric"
        common_name  = "fabric"
      }
    }
    x509_config {
      ca_options {
        is_ca = true
      }
      key_usage {
        base_key_usage {
          cert_sign = true
          crl_sign  = true
        }
        extended_key_usage {
          server_auth = true
        }
      }
    }
  }
  key_spec {
    algorithm = "EC_P256_SHA256"
  }
}

resource "google_privateca_ca_pool_iam_member" "member" {
  ca_pool = google_privateca_ca_pool.pool.id
  role    = "roles/privateca.certificateManager"
  member  = "serviceAccount:service-123456789@gcp-sa-networksecurity.iam.gserviceaccount.com"
}

module "secure-web-proxy" {
  source     = "./fabric/modules/net-swp"
  project_id = "my-project"
  region     = "europe-west4"
  name       = "secure-web-proxy"
  network    = "projects/my-project/global/networks/my-network"
  subnetwork = "projects/my-project/regions/europe-west4/subnetworks/my-subnetwork"
  certificates = [
    "projects/my-project/locations/europe-west4/certificates/swp"
  ]
  gateway_config = {
    addresses = ["10.142.68.3"]
  }
  tls_inspection_config = {
    create_config = {
      ca_pool = google_privateca_ca_pool.pool.id
    }
  }
  policy_rules = {
    tls-0 = {
      priority            = 1000
      session_matcher     = "host() == 'google.com'"
      application_matcher = "request.path.contains('generate_204')"
      tls_inspect         = true
    }
  }
}
# tftest modules=1 resources=7 inventory=tls.yaml
```

You can also refer to existing TLS inspection policies (even cross-project).

```hcl
module "secure-web-proxy" {
  source     = "./fabric/modules/net-swp"
  project_id = "my-project"
  region     = "europe-west4"
  name       = "secure-web-proxy"
  network    = "projects/my-project/global/networks/my-network"
  subnetwork = "projects/my-project/regions/europe-west4/subnetworks/my-subnetwork"
  certificates = [
    "projects/my-project/locations/europe-west4/certificates/swp"
  ]
  gateway_config = {
    addresses = ["10.142.68.3"]
  }
  tls_inspection_config = {
    id = "projects/another-project/locations/europe-west1/tlsInspectionPolicies/tls-ip-0"
  }
  policy_rules = {
    tls-0 = {
      priority            = 1000
      session_matcher     = "host() == 'google.com'"
      application_matcher = "request.path.contains('generate_204')"
      tls_inspect         = true
    }
  }
}
# tftest modules=1 resources=3 inventory=tls-no-ip.yaml
```

## Secure Web Proxy as transparent proxy
To use Secure Web Proxy as transparent proxy, define it as a default gateway for the tag or create policy based routes as described in the [documentation](https://cloud.google.com/secure-web-proxy/docs/deploy-next-hop). Secure Web Proxy passes only traffic on the ports that it listens. Configure rules as documented in earlier sections.

```hcl
locals {
  swp_name = "gateway"
}

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "swp-network"
  routes = {
    gateway = {
      dest_range    = "0.0.0.0/0",
      priority      = 100
      tags          = ["swp"] # only traffic from instances tagged 'swp' will be inspected
      next_hop_type = "ilb",
      next_hop      = module.addresses.internal_addresses[local.swp_name].address
    }
  }
  subnets_proxy_only = [ # SWP requires proxy-only subnet
    {
      ip_cidr_range = "10.0.1.0/24"
      name          = "regional-proxy"
      region        = var.region
      active        = true
    }
  ]
  subnets = [
    {
      ip_cidr_range = "10.0.2.0/24"
      name          = "production"
      region        = var.region
    }
  ]
}

module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    (local.swp_name) = {
      region     = var.region
      subnetwork = module.vpc.subnet_self_links["${var.region}/production"]
    }
  }
}

module "secure-web-proxy" {
  source     = "./fabric/modules/net-swp"
  project_id = var.project_id
  region     = var.region
  name       = local.swp_name
  network    = module.vpc.id
  subnetwork = module.vpc.subnets["${var.region}/production"].id
  gateway_config = {
    addresses             = [module.addresses.internal_addresses[local.swp_name].address]
    next_hop_routing_mode = true
    ports                 = [80, 443] # specify all ports to be intercepted
  }
  policy_rules = {
    proxy-rule = {
      priority        = 100
      session_matcher = "true" # pass all traffic
      tls_inspect     = false
    }
  }
}

# tftest inventory=transparent-proxy.yaml e2e
```

## Factories

URL lists and policies rules can also be defined via YAML-based factories, similarly to several other modules. Data coming from factories is internally merged with variables data, with factories having precedence in case duplicate keys are present in both.

```hcl
module "secure-web-proxy" {
  source     = "./fabric/modules/net-swp"
  project_id = "my-project"
  region     = "europe-west4"
  name       = "secure-web-proxy"
  network    = "projects/my-project/global/networks/my-network"
  subnetwork = "projects/my-project/regions/europe-west4/subnetworks/my-subnetwork"
  certificates = [
    "projects/my-project/locations/europe-west4/certificates/secure-web-proxy-cert"
  ]
  factories_config = {
    policy_rules = "data/policy-rules"
    url_lists    = "data/url-lists"
  }
  gateway_config = {
    addresses = ["10.142.68.3"]
    ports     = [80, 443]
    labels = {
      example = "value"
    }
  }
  policy_rules_contexts = {
    service_accounts = {
      foo = "foo@my-prj.iam.gserviceaccount.com"
    }
  }
}
# tftest modules=1 resources=5 files=0,1,2 inventory=factories.yaml
```

URL list definitions:

```yaml
description: URL list 0
values:
  - www.example.com
  - about.example.com
  - "*.google.com"
  - "github.com/example-org/*"
# tftest-file id=0 path=data/url-lists/list-0.yaml schema=url-list.schema.json
```

Policy rule definitions:

```yaml
priority: 1000
session_matcher: "inUrlList(host(), '%s')"
matcher_args:
  session:
    - url_list:list-0
# tftest-file id=1 path=data/policy-rules/url-list-0.yaml schema=policy-rule.schema.json
```

```yaml
priority: 1001
session_matcher: "source.matchServiceAccount('%s')"
matcher_args:
  session:
    - service_account:foo
# tftest-file id=2 path=data/policy-rules/service-account-0.yaml schema=policy-rule.schema.json
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [gateway_config](variables.tf#L40) | Optional Secure Web Gateway configuration. | <code title="object&#40;&#123;&#10;  addresses                &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  delete_router_on_destroy &#61; optional&#40;bool, true&#41;&#10;  labels                   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  next_hop_routing_mode    &#61; optional&#40;bool, false&#41;&#10;  ports                    &#61; optional&#40;list&#40;string&#41;, &#91;443&#93;&#41;&#10;  scope                    &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L53) | Name of the Secure Web Proxy resource. | <code>string</code> | ✓ |  |
| [network](variables.tf#L58) | Name of the network the Secure Web Proxy is deployed into. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L108) | Project id of the project that holds the network. | <code>string</code> | ✓ |  |
| [region](variables.tf#L113) | Region where resources will be created. | <code>string</code> | ✓ |  |
| [subnetwork](variables.tf#L133) | Name of the subnetwork the Secure Web Proxy is deployed into. | <code>string</code> | ✓ |  |
| [certificates](variables.tf#L17) | List of certificates to be used for Secure Web Proxy. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [description](variables.tf#L24) | Optional description for the created resources. | <code>string</code> |  | <code>&#34;Managed by Terraform.&#34;</code> |
| [factories_config](variables.tf#L30) | Path to folder with YAML resource description data files. | <code title="object&#40;&#123;&#10;  policy_rules &#61; optional&#40;string&#41;&#10;  url_lists    &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [policy_rules](variables.tf#L63) | Policy rules definitions. Merged with policy rules defined via the factory. | <code title="map&#40;object&#40;&#123;&#10;  priority            &#61; number&#10;  allow               &#61; optional&#40;bool, true&#41;&#10;  description         &#61; optional&#40;string&#41;&#10;  enabled             &#61; optional&#40;bool, true&#41;&#10;  application_matcher &#61; optional&#40;string&#41;&#10;  session_matcher     &#61; optional&#40;string&#41;&#10;  tls_inspect         &#61; optional&#40;bool&#41;&#10;  matcher_args &#61; optional&#40;object&#40;&#123;&#10;    application &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    session     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [policy_rules_contexts](variables.tf#L97) | Replacement contexts for policy rules matcher arguments. | <code title="object&#40;&#123;&#10;  secure_tags      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  url_lists        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_attachment](variables.tf#L118) | PSC service attachment configuration. | <code title="object&#40;&#123;&#10;  nat_subnets           &#61; list&#40;string&#41;&#10;  automatic_connection  &#61; optional&#40;bool, false&#41;&#10;  consumer_accept_lists &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  consumer_reject_lists &#61; optional&#40;list&#40;string&#41;&#41;&#10;  description           &#61; optional&#40;string&#41;&#10;  domain_name           &#61; optional&#40;string&#41;&#10;  enable_proxy_protocol &#61; optional&#40;bool, false&#41;&#10;  reconcile_connections &#61; optional&#40;bool&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [tls_inspection_config](variables.tf#L138) | TLS inspection configuration. | <code title="object&#40;&#123;&#10;  create_config &#61; optional&#40;object&#40;&#123;&#10;    ca_pool               &#61; optional&#40;string, null&#41;&#10;    description           &#61; optional&#40;string, null&#41;&#10;    exclude_public_ca_set &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;, null&#41;&#10;  id &#61; optional&#40;string, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [url_lists](variables.tf#L159) | URL lists. | <code title="map&#40;object&#40;&#123;&#10;  values      &#61; list&#40;string&#41;&#10;  description &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [gateway](outputs.tf#L17) | The gateway resource. |  |
| [gateway_security_policy](outputs.tf#L22) | The gateway security policy resource. |  |
| [id](outputs.tf#L27) | ID of the gateway resource. |  |
| [service_attachment](outputs.tf#L32) | ID of the service attachment resource, if created. |  |
<!-- END TFDOC -->
