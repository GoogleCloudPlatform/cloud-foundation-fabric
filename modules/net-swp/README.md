# Google Cloud Secure Web Proxy

This module allows creation and management of [Secure Web Proxy](https://cloud.google.com/secure-web-proxy/docs/overview) alongside with its security
policies:

- Secure tag based rules via the `policy_rules.secure_tags` variable
- Url list rules via the `policy_rules.url_lists` variable
- Custom rules via the `policy_rules.custom`

It also allows to deploy SWP as a Private Service Connect service. 
This means that a single SWP deployment can be used from across different VPCs, regardless of whether they are interconnected.

A [Proxy-only subnet](https://cloud.google.com/load-balancing/docs/proxy-only-subnets) must exist in the VPC where SWP is deployed.

When deploying SWP, the required ad-hoc [Cloud Router](https://cloud.google.com/network-connectivity/docs/router) is also created.

## Examples

### Minimal Secure Web Proxy

(Note that this will not allow any request to pass.)

```hcl
module "secure-web-proxy" {
  source = "./fabric/modules/net-swp"

  project_id   = "my-project"
  region       = "europe-west4"
  name         = "secure-web-proxy"
  network      = "projects/my-project/global/networks/my-network"
  subnetwork   = "projects/my-project/regions/europe-west4/subnetworks/my-subnetwork"
  addresses    = ["10.142.68.3"]
  certificates = ["projects/my-project/locations/europe-west4/certificates/secure-web-proxy-cert"]
  labels = {
    example = "value"
  }
}
# tftest modules=1 resources=2 inventory=basic.yaml
```

### PSC service attachments

The optional `service_attachment` variable allows [deploying SWP as a Private Service Connect service attachment](https://cloud.google.com/secure-web-proxy/docs/deploy-service-attachment)

```hcl
module "secure-web-proxy" {
  source = "./fabric/modules/net-swp"

  project_id   = "my-project"
  region       = "europe-west4"
  name         = "secure-web-proxy"
  network      = "projects/my-project/global/networks/my-network"
  subnetwork   = "projects/my-project/regions/europe-west4/subnetworks/my-subnetwork"
  addresses    = ["10.142.68.3"]
  certificates = ["projects/my-project/locations/europe-west4/certificates/secure-web-proxy-cert"]
  labels = {
    example = "value"
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

### Secure Web Proxy with rules

```hcl
module "secure-web-proxy" {
  source = "./fabric/modules/net-swp"

  project_id   = "my-project"
  region       = "europe-west4"
  name         = "secure-web-proxy"
  network      = "projects/my-project/global/networks/my-network"
  subnetwork   = "projects/my-project/regions/europe-west4/subnetworks/my-subnetwork"
  addresses    = ["10.142.68.3"]
  certificates = ["projects/my-project/locations/europe-west4/certificates/secure-web-proxy-cert"]
  ports        = [80, 443]
  policy_rules = {
    secure_tags = {
      secure-tag-1 = {
        tag      = "tagValues/281484836404786"
        priority = 1000
      }
      secure-tag-2 = {
        tag             = "tagValues/281484836404786"
        session_matcher = "host() != 'google.com'"
        priority        = 1001
      }
    }
    url_lists = {
      url-list-1 = {
        url_list = "my-url-list"
        values   = ["www.google.com", "google.com"]
        priority = 1002
      }
      url-list-2 = {
        url_list        = "projects/my-project/locations/europe-west4/urlLists/my-url-list"
        session_matcher = "source.matchServiceAccount('my-sa@my-project.iam.gserviceaccount.com')"
        enabled         = false
        priority        = 1003
      }
    }
    custom = {
      custom-rule-1 = {
        priority        = 1004
        session_matcher = "host() == 'google.com'"
        action          = "DENY"
      }
    }
  }
}
# tftest modules=1 resources=8 inventory=rules.yaml
```

### Secure Web Proxy with TLS inspection

```hcl
resource "google_privateca_ca_pool" "pool" {
  name     = "secure-web-proxy-capool"
  location = "europe-west4"
  project  = "my-project"

  tier = "DEVOPS"
}

resource "google_privateca_certificate_authority" "ca" {
  pool                     = google_privateca_ca_pool.pool.name
  certificate_authority_id = "secure-web-proxy-ca"
  location                 = "europe-west4"
  project                  = "my-project"

  deletion_protection = "false"

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
  lifetime = "1209600s"
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
  source = "./fabric/modules/net-swp"

  project_id   = "my-project"
  region       = "europe-west4"
  name         = "secure-web-proxy"
  network      = "projects/my-project/global/networks/my-network"
  subnetwork   = "projects/my-project/regions/europe-west4/subnetworks/my-subnetwork"
  addresses    = ["10.142.68.3"]
  certificates = ["projects/my-project/locations/europe-west4/certificates/secure-web-proxy-cert"]
  ports        = [443]
  policy_rules = {
    custom = {
      custom-rule-1 = {
        priority               = 1000
        session_matcher        = "host() == 'google.com'"
        application_matcher    = "request.path.contains('generate_204')"
        action                 = "ALLOW"
        tls_inspection_enabled = true
      }
    }
  }
  tls_inspection_config = {
    ca_pool = google_privateca_ca_pool.pool.id
  }
}
# tftest modules=1 resources=7 inventory=tls.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [addresses](variables.tf#L19) | One or more IP addresses to be used for Secure Web Proxy. | <code>list&#40;string&#41;</code> | ✓ |  |
| [certificates](variables.tf#L28) | List of certificates to be used for Secure Web Proxy. | <code>list&#40;string&#41;</code> | ✓ |  |
| [name](variables.tf#L51) | Name of the Secure Web Proxy resource. | <code>string</code> | ✓ |  |
| [network](variables.tf#L56) | Name of the network the Secure Web Proxy is deployed into. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L120) | Project id of the project that holds the network. | <code>string</code> | ✓ |  |
| [region](variables.tf#L125) | Region where resources will be created. | <code>string</code> | ✓ |  |
| [subnetwork](variables.tf#L151) | Name of the subnetwork the Secure Web Proxy is deployed into. | <code>string</code> | ✓ |  |
| [delete_swg_autogen_router_on_destroy](variables.tf#L33) | Delete automatically provisioned Cloud Router on destroy. | <code>bool</code> |  | <code>true</code> |
| [description](variables.tf#L39) | Optional description for the created resources. | <code>string</code> |  | <code>&#34;Managed by Terraform.&#34;</code> |
| [labels](variables.tf#L45) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [policy_rules](variables.tf#L61) | List of policy rule definitions, default to allow action. Available keys: secure_tags, url_lists, custom. URL lists that only have values set will be created. | <code title="object&#40;&#123;&#10;  secure_tags &#61; optional&#40;map&#40;object&#40;&#123;&#10;    tag                    &#61; string&#10;    session_matcher        &#61; optional&#40;string&#41;&#10;    application_matcher    &#61; optional&#40;string&#41;&#10;    priority               &#61; number&#10;    action                 &#61; optional&#40;string, &#34;ALLOW&#34;&#41;&#10;    enabled                &#61; optional&#40;bool, true&#41;&#10;    tls_inspection_enabled &#61; optional&#40;bool, false&#41;&#10;    description            &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#10;&#10;  url_lists &#61; optional&#40;map&#40;object&#40;&#123;&#10;    url_list               &#61; string&#10;    values                 &#61; optional&#40;list&#40;string&#41;&#41;&#10;    session_matcher        &#61; optional&#40;string&#41;&#10;    application_matcher    &#61; optional&#40;string&#41;&#10;    priority               &#61; number&#10;    action                 &#61; optional&#40;string, &#34;ALLOW&#34;&#41;&#10;    enabled                &#61; optional&#40;bool, true&#41;&#10;    tls_inspection_enabled &#61; optional&#40;bool, false&#41;&#10;    description            &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#10;&#10;  custom &#61; optional&#40;map&#40;object&#40;&#123;&#10;    session_matcher        &#61; optional&#40;string&#41;&#10;    application_matcher    &#61; optional&#40;string&#41;&#10;    priority               &#61; number&#10;    action                 &#61; optional&#40;string, &#34;ALLOW&#34;&#41;&#10;    enabled                &#61; optional&#40;bool, true&#41;&#10;    tls_inspection_enabled &#61; optional&#40;bool, false&#41;&#10;    description            &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ports](variables.tf#L114) | Ports to use for Secure Web Proxy. | <code>list&#40;number&#41;</code> |  | <code>&#91;443&#93;</code> |
| [scope](variables.tf#L130) | Scope determines how configuration across multiple Gateway instances are merged. | <code>string</code> |  | <code>null</code> |
| [service_attachment](variables.tf#L136) | PSC service attachment configuration. | <code title="object&#40;&#123;&#10;  nat_subnets           &#61; list&#40;string&#41;&#10;  automatic_connection  &#61; optional&#40;bool, false&#41;&#10;  consumer_accept_lists &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  consumer_reject_lists &#61; optional&#40;list&#40;string&#41;&#41;&#10;  description           &#61; optional&#40;string&#41;&#10;  domain_name           &#61; optional&#40;string&#41;&#10;  enable_proxy_protocol &#61; optional&#40;bool, false&#41;&#10;  reconcile_connections &#61; optional&#40;bool&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [tls_inspection_config](variables.tf#L156) | TLS inspection configuration. | <code title="object&#40;&#123;&#10;  ca_pool               &#61; optional&#40;string, null&#41;&#10;  exclude_public_ca_set &#61; optional&#40;bool, false&#41;&#10;  description           &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [gateway](outputs.tf#L17) | The gateway resource. |  |
| [gateway_security_policy](outputs.tf#L22) | The gateway security policy resource. |  |
| [id](outputs.tf#L27) | ID of the gateway resource. |  |
| [service_attachment](outputs.tf#L32) | ID of the service attachment resource, if created. |  |
<!-- END TFDOC -->
