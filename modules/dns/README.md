# Google Cloud DNS Module

This module allows simple management of Google Cloud DNS zones and records. It supports creating public, private, forwarding, peering and service directory based zones.

For DNSSEC configuration, refer to the [`dns_managed_zone` documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone#dnssec_config).

## Examples

### Private Zone

```hcl
module "private-dns" {
  source          = "./modules/dns"
  project_id      = "myproject"
  type            = "private"
  name            = "test-example"
  domain          = "test.example."
  client_networks = [var.vpc.self_link]
  recordsets = {
    "A localhost" = { ttl = 300, records = ["127.0.0.1"] }
  }
}
# tftest modules=1 resources=2
```

### Forwarding Zone

```hcl
module "private-dns" {
  source          = "./modules/dns"
  project_id      = "myproject"
  type            = "forwarding"
  name            = "test-example"
  domain          = "test.example."
  client_networks = [var.vpc.self_link]
  forwarders      = { "10.0.1.1" = null, "1.2.3.4" = "private" }
}
# tftest modules=1 resources=1
```

### Peering Zone

```hcl
module "private-dns" {
  source          = "./modules/dns"
  project_id      = "myproject"
  type            = "peering"
  name            = "test-example"
  domain          = "test.example."
  client_networks = [var.vpc.self_link]
  peer_network    = var.vpc2.self_link
}
# tftest modules=1 resources=1
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [domain](variables.tf#L51) | Zone domain, must end with a period. | <code>string</code> | ✓ |  |
| [name](variables.tf#L62) | Zone name, must be unique within the project. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L73) | Project id for the zone. | <code>string</code> | ✓ |  |
| [client_networks](variables.tf#L21) | List of VPC self links that can see this zone. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [default_key_specs_key](variables.tf#L27) | DNSSEC default key signing specifications: algorithm, key_length, key_type, kind. | <code>any</code> |  | <code>&#123;&#125;</code> |
| [default_key_specs_zone](variables.tf#L33) | DNSSEC default zone signing specifications: algorithm, key_length, key_type, kind. | <code>any</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L39) | Domain description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [dnssec_config](variables.tf#L45) | DNSSEC configuration: kind, non_existence, state. | <code>any</code> |  | <code>&#123;&#125;</code> |
| [forwarders](variables.tf#L56) | Map of {IPV4_ADDRESS => FORWARDING_PATH} for 'forwarding' zone types. Path can be 'default', 'private', or null for provider default. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [peer_network](variables.tf#L67) | Peering network self link, only valid for 'peering' zone types. | <code>string</code> |  | <code>null</code> |
| [recordsets](variables.tf#L78) | Map of DNS recordsets in \"type name\" => {ttl, [records]} format. | <code title="map&#40;object&#40;&#123;&#10;  ttl     &#61; number&#10;  records &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_directory_namespace](variables.tf#L94) | Service directory namespace id (URL), only valid for 'service-directory' zone types. | <code>string</code> |  | <code>null</code> |
| [type](variables.tf#L100) | Type of zone to create, valid values are 'public', 'private', 'forwarding', 'peering', 'service-directory'. | <code>string</code> |  | <code>&#34;private&#34;</code> |
| [zone_create](variables.tf#L110) | Create zone. When set to false, uses a data source to reference existing zone. | <code>bool</code> |  | <code>true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [dns_keys](outputs.tf#L17) | DNSKEY and DS records of DNSSEC-signed managed zones. |  |
| [domain](outputs.tf#L22) | The DNS zone domain. |  |
| [name](outputs.tf#L27) | The DNS zone name. |  |
| [name_servers](outputs.tf#L32) | The DNS zone name servers. |  |
| [type](outputs.tf#L37) | The DNS zone type. |  |
| [zone](outputs.tf#L42) | DNS zone resource. |  |

<!-- END TFDOC -->
