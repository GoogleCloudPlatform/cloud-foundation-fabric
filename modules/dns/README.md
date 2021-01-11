# Google Cloud DNS Module

This module allows simple management of Google Cloud DNS zones and records. It supports creating public, private, forwarding, peering and service directory based zones.

For DNSSEC configuration, refer to the [`dns_managed_zone` documentation](https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html#dnssec_config).

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
  recordsets = [
    { name = "localhost", type = "A", ttl = 300, records = ["127.0.0.1"] }
  ]
}
# tftest:modules=1:resources=2
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
# tftest:modules=1:resources=1
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
# tftest:modules=1:resources=1
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| domain | Zone domain, must end with a period. | <code title="">string</code> | ✓ |  |
| name | Zone name, must be unique within the project. | <code title="">string</code> | ✓ |  |
| project_id | Project id for the zone. | <code title="">string</code> | ✓ |  |
| *client_networks* | List of VPC self links that can see this zone. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *default_key_specs_key* | DNSSEC default key signing specifications: algorithm, key_length, key_type, kind. | <code title="">any</code> |  | <code title="">{}</code> |
| *default_key_specs_zone* | DNSSEC default zone signing specifications: algorithm, key_length, key_type, kind. | <code title="">any</code> |  | <code title="">{}</code> |
| *description* | Domain description. | <code title="">string</code> |  | <code title="">Terraform managed.</code> |
| *dnssec_config* | DNSSEC configuration: kind, non_existence, state. | <code title="">any</code> |  | <code title="">{}</code> |
| *forwarders* | Map of {IPV4_ADDRESS => FORWARDING_PATH} for 'forwarding' zone types. Path can be 'default', 'private', or null for provider default. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *peer_network* | Peering network self link, only valid for 'peering' zone types. | <code title="">string</code> |  | <code title="">null</code> |
| *recordsets* | List of DNS record objects to manage. | <code title="list&#40;object&#40;&#123;&#10;name    &#61; string&#10;type &#61; string&#10;ttl     &#61; number&#10;records &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">list(object({...}))</code> |  | <code title="">[]</code> |
| *service_directory_namespace* | Service directory namespace id (URL), only valid for 'service-directory' zone types. | <code title="">string</code> |  | <code title="">null</code> |
| *type* | Type of zone to create, valid values are 'public', 'private', 'forwarding', 'peering', 'service-directory'. | <code title="">string</code> |  | <code title="private&#10;validation &#123;&#10;condition     &#61; contains&#40;&#91;&#34;public&#34;, &#34;private&#34;, &#34;forwarding&#34;, &#34;peering&#34;, &#34;service-directory&#34;&#93;, var.type&#41;&#10;error_message &#61; &#34;Zone must be one of &#39;public&#39;, &#39;private&#39;, &#39;forwarding&#39;, &#39;peering&#39;, &#39;service-directory&#39;.&#34;&#10;&#125;">...</code> |
| *zone_create* | Create zone. When set to false, uses a data source to reference existing zone. | <code title="">bool</code> |  | <code title="">true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| dns_keys | DNSKEY and DS records of DNSSEC-signed managed zones. |  |
| domain | The DNS zone domain. |  |
| name | The DNS zone name. |  |
| name_servers | The DNS zone name servers. |  |
| type | The DNS zone type. |  |
| zone | DNS zone resource. |  |
<!-- END TFDOC -->
