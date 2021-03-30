# Google Cloud VPC Firewall

This module allows creation and management of different types of firewall rules for a single VPC network:

- blanket ingress rules based on IP ranges that allow all traffic via the `admin_ranges` variable
- simplified tag-based ingress rules for the HTTP, HTTPS and SSH protocols via the `xxx_source_ranges` variables; HTTP and HTTPS tags match those set by the console via the "Allow HTTP(S) traffic" instance flags
- custom rules via the `custom_rules` variables

The simplified tag-based rules are enabled by default, set to the ranges of the GCP health checkers for HTTP/HTTPS, and the IAP forwarders for SSH. To disable them set the corresponding variables to empty lists.

## Examples

### Minimal open firewall

This is often useful for prototyping or testing infrastructure, allowing open ingress from the private range, enabling SSH to private addresses from IAP, and HTTP/HTTPS from the health checkers.

```hcl
module "firewall" {
  source               = "./modules/net-vpc-firewall"
  project_id           = "my-project"
  network              = "my-network"
  admin_ranges_enabled = true
  admin_ranges         = ["10.0.0.0/8"]
}
# tftest:modules=1:resources=4
```

### Custom rules

This is an example of how to define custom rules, with a sample rule allowing open ingress for the NTP protocol to instances with the `ntp-svc` tag.

```hcl
module "firewall" {
  source               = "./modules/net-vpc-firewall"
  project_id           = "my-project"
  network              = "my-network"
  admin_ranges_enabled = true
  admin_ranges         = ["10.0.0.0/8"]
  custom_rules = {
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
# tftest:modules=1:resources=5
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
| *http_source_ranges* | List of IP CIDR ranges for tag-based HTTP rule, defaults to the health checkers ranges. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]</code> |
| *https_source_ranges* | List of IP CIDR ranges for tag-based HTTPS rule, defaults to the health checkers ranges. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]</code> |
| *ssh_source_ranges* | List of IP CIDR ranges for tag-based SSH rule, defaults to the IAP forwarders range. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["35.235.240.0/20"]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| admin_ranges | Admin ranges data. |  |
| custom_egress_allow_rules | Custom egress rules with allow blocks. |  |
| custom_egress_deny_rules | Custom egress rules with allow blocks. |  |
| custom_ingress_allow_rules | Custom ingress rules with allow blocks. |  |
| custom_ingress_deny_rules | Custom ingress rules with deny blocks. |  |
<!-- END TFDOC -->
