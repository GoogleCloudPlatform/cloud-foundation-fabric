# Google Cloud VPC Firewall

This module allows creation of a minimal VPC firewall, supporting basic configurable rules for IP range-based intra-VPC and administrator ingress,  tag-based SSH/HTTP/HTTPS ingress, and custom rule definitions.

The HTTP and HTTPS rules use the same network tags that are assigned to instances when the "Allow HTTP[S] traffic" checkbox is flagged in the Cloud Console. The SSH rule uses a generic `ssh` tag.

All IP source ranges are configurable through variables, and are set by default to `0.0.0.0/0` for tag-based rules. Allowed protocols and/or ports for the intra-VPC rule are also configurable through a variable.

## Example

```hcl
module "firewall" {
  source               = "../modules/net-vpc-firewall"
  project_id           = local.projects.host
  network              = module.vpc.name
  admin_ranges_enabled = true
  admin_ranges         = values(var.ip_ranges)
  custom_rules = {
    health-checks = {
      description          = "HTTP health checks."
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      ranges               = (
        data.google_netblock_ip_ranges.health-checkers.cidr_blocks_ipv4
      )
      targets              = ["health-checks"]
      use_service_accounts = false
      rules                = [{ protocol = "tcp", ports = [80] }]
      extra_attributes     = {}
    },
    ntp-svc = {
      description          = "NTP service."
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      ranges               = ["0.0.0.0/0"]
      targets              = ["ntp-svc"]
      use_service_accounts = false
      rules                = [{ protocol = "udp", ports = [123] }]
      extra_attributes     = {}
    }
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| network | Name of the network this set of firewall rules applies to. | <code title="">string</code> | ✓ |  |
| project_id | Project id of the project that holds the network. | <code title="">string</code> | ✓ |  |
| *admin_ranges* | IP CIDR ranges that have complete access to all subnets. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *admin_ranges_enabled* | Enable admin ranges-based rules. | <code title="">bool</code> |  | <code title="">false</code> |
| *custom_rules* | List of custom rule definitions (refer to variables file for syntax). | <code title="map&#40;object&#40;&#123;&#10;description          &#61; string&#10;direction            &#61; string&#10;action               &#61; string &#35; &#40;allow&#124;deny&#41;&#10;ranges               &#61; list&#40;string&#41;&#10;sources              &#61; list&#40;string&#41;&#10;targets              &#61; list&#40;string&#41;&#10;use_service_accounts &#61; bool&#10;rules &#61; list&#40;object&#40;&#123;&#10;protocol &#61; string&#10;ports    &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;&#10;extra_attributes &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *http_source_ranges* | List of IP CIDR ranges for tag-based HTTP rule, defaults to 0.0.0.0/0. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["0.0.0.0/0"]</code> |
| *https_source_ranges* | List of IP CIDR ranges for tag-based HTTPS rule, defaults to 0.0.0.0/0. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["0.0.0.0/0"]</code> |
| *ssh_source_ranges* | List of IP CIDR ranges for tag-based SSH rule, defaults to 0.0.0.0/0. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["0.0.0.0/0"]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| admin_ranges | Admin ranges data. |  |
| custom_egress_allow_rules | Custom egress rules with allow blocks. |  |
| custom_egress_deny_rules | Custom egress rules with allow blocks. |  |
| custom_ingress_allow_rules | Custom ingress rules with allow blocks. |  |
| custom_ingress_deny_rules | Custom ingress rules with deny blocks. |  |
<!-- END TFDOC -->
