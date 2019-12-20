# Google Cloud VPC Firewall

This module allows creation of a minimal VPC firewall, supporting basic configurable rules for IP range-based intra-VPC and administrator ingress,  tag-based SSH/HTTP/HTTPS ingress, and custom rule definitions.

The HTTP and HTTPS rules use the same network tags that are assigned to instances when the "Allow HTTP[S] traffic" checkbox is flagged in the Cloud Console. The SSH rule uses a generic `ssh` tag.

All IP source ranges are configurable through variables, and are set by default to `0.0.0.0/0` for tag-based rules. Allowed protocols and/or ports for the intra-VPC rule are also configurable through a variable.

Custom rules are set through a map where keys are rule names, and values use this custom type:

```hcl
map(object({
  description          = string
  direction            = string       # (INGRESS|EGRESS)
  action               = string       # (allow|deny)
  ranges               = list(string) # list of IP CIDR ranges
  sources              = list(string) # tags or SAs (ignored for EGRESS)
  targets              = list(string) # tags or SAs
  use_service_accounts = bool         # use tags or SAs in sources/targets
  rules = list(object({
    protocol = string
    ports    = list(string)
  }))
  extra_attributes = map(string)      # map, optional keys disabled or priority
}))
```

The resources created/managed by this module are:

- one optional ingress rule from internal CIDR ranges, only allowing ICMP by default
- one optional ingress rule from admin CIDR ranges, allowing all protocols on all ports
- one optional ingress rule for SSH on network tag `ssh`
- one optional ingress rule for HTTP on network tag `http-server`
- one optional ingress rule for HTTPS on network tag `https-server`
- one or more optional custom rules


## Usage

Basic usage of this module is as follows:

```hcl
module "net-firewall" {
  source                  = "terraform-google-modules/network/google//modules/fabric-net-firewall"
  project_id              = "my-project"
  network                 = "my-vpc"
  internal_ranges_enabled = true
  internal_ranges         = ["10.0.0.0/0"]
  custom_rules = {
    ingress-sample = {
      description          = "Dummy sample ingress rule, tag-based."
      direction            = "INGRESS"
      action               = "allow"
      ranges               = ["192.168.0.0"]
      sources              = ["spam-tag"]
      targets              = ["foo-tag", "egg-tag"]
      use_service_accounts = false
      rules = [
        {
          protocol = "tcp"
          ports    = []
        }
      ]
      extra_attributes = {}
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
