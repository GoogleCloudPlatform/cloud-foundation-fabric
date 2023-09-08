# Google Cloud DNS Module

This module allows simple management of Google Cloud DNS zones and records. It supports creating public, private, forwarding, peering, service directory and reverse-managed based zones. To create inbound/outbound server policies, please have a look at the [net-vpc](../net-vpc/README.md) module.

For DNSSEC configuration, refer to the [`dns_managed_zone` documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone#dnssec_config).

## Examples

### Private Zone

```hcl
module "private-dns" {
  source     = "./fabric/modules/dns"
  project_id = "myproject"
  name       = "test-example"
  zone_config = {
    domain = "test.example."
    private = {
      client_networks = [var.vpc.self_link]
    }
  }
  recordsets = {
    "A localhost" = { records = ["127.0.0.1"] }
    "A myhost"    = { ttl = 600, records = ["10.0.0.120"] }
  }
  iam = {
    "roles/dns.admin" = ["group:dns-administrators@myorg.com"]
  }
}
# tftest modules=1 resources=5 inventory=private-zone.yaml
```

### Forwarding Zone

```hcl
module "private-dns" {
  source     = "./fabric/modules/dns"
  project_id = "myproject"
  name       = "test-example"
  zone_config = {
    domain = "test.example."
    forwarding = {
      client_networks = [var.vpc.self_link]
      forwarders      = { "10.0.1.1" = null, "1.2.3.4" = "private" }
    }
  }
}
# tftest modules=1 resources=2 inventory=forwarding-zone.yaml
```

### Peering Zone

```hcl
module "private-dns" {
  source     = "./fabric/modules/dns"
  project_id = "myproject"
  name       = "test-example"
  zone_config = {
    domain = "."
    peering = {
      client_networks = [var.vpc.self_link]
      peer_network    = var.vpc2.self_link
    }
  }
}
# tftest modules=1 resources=2 inventory=peering-zone.yaml
```

### Routing Policies

```hcl
module "private-dns" {
  source     = "./fabric/modules/dns"
  project_id = "myproject"
  name       = "test-example"
  zone_config = {
    domain = "test.example."
    private = {
      client_networks = [var.vpc.self_link]
    }
  }
  recordsets = {
    "A regular" = { records = ["10.20.0.1"] }
    "A geo" = {
      geo_routing = [
        { location = "europe-west1", records = ["10.0.0.1"] },
        { location = "europe-west2", records = ["10.0.0.2"] },
        { location = "europe-west3", records = ["10.0.0.3"] }
      ]
    }

    "A wrr" = {
      ttl = 600
      wrr_routing = [
        { weight = 0.6, records = ["10.10.0.1"] },
        { weight = 0.2, records = ["10.10.0.2"] },
        { weight = 0.2, records = ["10.10.0.3"] }
      ]
    }
  }
}
# tftest modules=1 resources=5 inventory=routing-policies.yaml
```

### Reverse Lookup Zone

```hcl
module "private-dns" {
  source     = "./fabric/modules/dns"
  project_id = "myproject"
  name       = "test-example"
  zone_config = {
    domain = "0.0.10.in-addr.arpa."
    private = {
      client_networks = [var.vpc.self_link]
    }
  }
}
# tftest modules=1 resources=2 inventory=reverse-zone.yaml
```

### Public Zone

```hcl
module "public-dns" {
  source     = "./fabric/modules/dns"
  project_id = "myproject"
  name       = "example"
  zone_config = {
    domain = "example.com."
    public = {}
  }
  recordsets = {
    "A myhost" = { ttl = 300, records = ["127.0.0.1"] }
  }
  iam = {
    "roles/dns.admin" = ["group:dns-administrators@myorg.com"]
  }
}
# tftest modules=1 resources=4 inventory=public-zone.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L29) | Zone name, must be unique within the project. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L34) | Project id for the zone. | <code>string</code> | ✓ |  |
| [description](variables.tf#L17) | Domain description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [iam](variables.tf#L23) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>null</code> |
| [recordsets](variables.tf#L39) | Map of DNS recordsets in \"type name\" => {ttl, [records]} format. | <code title="map&#40;object&#40;&#123;&#10;  ttl     &#61; optional&#40;number, 300&#41;&#10;  records &#61; optional&#40;list&#40;string&#41;&#41;&#10;  geo_routing &#61; optional&#40;list&#40;object&#40;&#123;&#10;    location &#61; string&#10;    records  &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  wrr_routing &#61; optional&#40;list&#40;object&#40;&#123;&#10;    weight  &#61; number&#10;    records &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [zone_config](variables.tf#L74) | DNS zone configuration. | <code title="object&#40;&#123;&#10;  domain &#61; string&#10;  forwarding &#61; optional&#40;object&#40;&#123;&#10;    forwarders      &#61; optional&#40;map&#40;string&#41;&#41;&#10;    client_networks &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  peering &#61; optional&#40;object&#40;&#123;&#10;    client_networks &#61; list&#40;string&#41;&#10;    peer_network    &#61; string&#10;  &#125;&#41;&#41;&#10;  public &#61; optional&#40;object&#40;&#123;&#10;    dnssec_config &#61; optional&#40;object&#40;&#123;&#10;      non_existence &#61; optional&#40;string, &#34;nsec3&#34;&#41;&#10;      state         &#61; string&#10;      key_signing_key &#61; optional&#40;object&#40;&#10;        &#123; algorithm &#61; string, key_length &#61; number &#125;&#41;,&#10;        &#123; algorithm &#61; &#34;rsasha256&#34;, key_length &#61; 2048 &#125;&#10;      &#41;&#10;      zone_signing_key &#61; optional&#40;object&#40;&#10;        &#123; algorithm &#61; string, key_length &#61; number &#125;&#41;,&#10;        &#123; algorithm &#61; &#34;rsasha256&#34;, key_length &#61; 1024 &#125;&#10;      &#41;&#10;    &#125;&#41;&#41;&#10;    enable_logging &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  private &#61; optional&#40;object&#40;&#123;&#10;    client_networks             &#61; list&#40;string&#41;&#10;    service_directory_namespace &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [dns_keys](outputs.tf#L17) | DNSKEY and DS records of DNSSEC-signed managed zones. |  |
| [domain](outputs.tf#L22) | The DNS zone domain. |  |
| [id](outputs.tf#L27) | Fully qualified zone id. |  |
| [name](outputs.tf#L32) | The DNS zone name. |  |
| [name_servers](outputs.tf#L37) | The DNS zone name servers. |  |
| [zone](outputs.tf#L42) | DNS zone resource. |  |
<!-- END TFDOC -->
