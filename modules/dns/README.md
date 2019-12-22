# Terraform Google Cloud DNS Module

This module makes it easy to create Google Cloud DNS zones of different types, and manage their records. It supports creating public, private, forwarding, and peering zones.

The resources/services/activations/deletions that this module will create/trigger are:

- One `google_dns_managed_zone` for the zone
- Zero or more `google_dns_record_set` for the zone records

## Usage

Basic usage of this module for a private zone is as follows:

```hcl
module "dns-private-zone" {
  source  = "./modules/dns
  project_id = "my-project"
  type       = "private"
  name       = "example-com"
  domain     = "example.com."
  client_networks = [var.vpc_self_link]
  recordsets = [
    {name = "", type = "NS", ttl = 300, records = ["127.0.0.1"]},
    {name = "localhost", type = "A", ttl = 300, records = ["127.0.0.1"]},
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

## Requirements

### IAM Roles

The following roles must be used to provision the resources in this module:

- Storage Admin: `roles/dns.admin`

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- Google Cloud DNS API: `dns.googleapis.com`

## DNSSEC

For DNSSEC configuration, refer to the [`dns_managed_zone` documentation](https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html#dnssec_config).