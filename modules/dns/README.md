# Google Cloud DNS Module

This module allows simple management of Google Cloud DNS zones and records. It supports creating public, private, forwarding, and peering zones. For DNSSEC configuration, refer to the [`dns_managed_zone` documentation](https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html#dnssec_config).

## Example

```hcl
module "private-dns" {
  source          = "./modules/dns"
  project_id      = "myproject"
  type            = "private"
  name            = "test-example"
  domain          = "test.example."
  client_networks = [var.vpc_self_link]
  recordsets = [
    { name = "localhost", type = "A", ttl = 300, records = ["127.0.0.1"] }
  ]
}
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
| *forwarders* | List of target name servers, only valid for 'forwarding' zone types. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *peer_network* | Peering network self link, only valid for 'peering' zone types. | <code title="">string</code> |  | <code title=""></code> |
| *recordsets* | List of DNS record objects to manage. | <code title="list&#40;object&#40;&#123;&#10;name    &#61; string&#10;type &#61; string&#10;ttl     &#61; number&#10;records &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">list(object({...}))</code> |  | <code title="">[]</code> |
| *type* | Type of zone to create, valid values are 'public', 'private', 'forwarding', 'peering'. | <code title="">string</code> |  | <code title="">private</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| domain | The DNS zone domain. |  |
| name | The DNS zone name. |  |
| name_servers | The DNS zone name servers. |  |
| type | The DNS zone type. |  |
| zone | DNS zone resource. |  |
<!-- END TFDOC -->
