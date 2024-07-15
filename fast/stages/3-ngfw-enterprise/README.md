# Network Security

This stage sets up the network firewall, including hierarchical firewall policies, network firewall policies and -optionally- NGFW Enterprise.

...
<!-- TFDOC OPTS files:1 show_extra:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [main.tf](./main.tf) | Next-Generation Firewall Enterprise configuration. | <code>project</code> | <code>google_network_security_firewall_endpoint</code> |
| [net-dev.tf](./net-dev.tf) | Security components for dev spoke VPC. | <code>net-firewall-policy</code> · <code>project</code> | <code>google_network_security_firewall_endpoint_association</code> · <code>google_network_security_security_profile</code> · <code>google_network_security_security_profile_group</code> |
| [net-prod.tf](./net-prod.tf) | Security components for prod spoke VPC. | <code>net-firewall-policy</code> · <code>project</code> | <code>google_network_security_firewall_endpoint_association</code> · <code>google_network_security_security_profile</code> · <code>google_network_security_security_profile_group</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |  |
| [variables-fast.tf](./variables-fast.tf) | None |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [billing_account](variables-fast.tf#L17) | Billing account id. If billing account is not part of the same org set `is_org_level` to false. | <code title="object&#40;&#123;&#10;  id           &#61; string&#10;  is_org_level &#61; optional&#40;bool, true&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [folder_ids](variables-fast.tf#L30) | Folders to be used for the networking resources in folders/nnnnnnnnnnn format. If null, folder will be created. | <code title="object&#40;&#123;&#10;  networking-dev  &#61; string&#10;  networking-prod &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>1-resman</code> |
| [organization](variables-fast.tf#L39) | Organization details. | <code title="object&#40;&#123;&#10;  domain      &#61; string&#10;  id          &#61; number&#10;  customer_id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>00-globals</code> |
| [prefix](variables-fast.tf#L49) | Prefix used for resources that need unique names. Use a maximum of 9 chars for organizations, and 11 chars for tenants. | <code>string</code> | ✓ |  | <code>0-bootstrap</code> |
| [vpc_self_links](variables-fast.tf#L59) | Self link for the shared VPC. | <code title="object&#40;&#123;&#10;  dev-spoke-0  &#61; string&#10;  prod-spoke-0 &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>2-networking</code> |
| [factories_config](variables.tf#L17) | Configuration for network resource factories. | <code title="object&#40;&#123;&#10;  data_dir &#61; optional&#40;string, &#34;data&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [ngfw_enterprise_config](variables.tf#L30) | NGFW Enterprise configuration. | <code title="object&#40;&#123;&#10;  endpoint_zones &#61; optional&#40;list&#40;string&#41;, &#91;&#34;europe-west1-a&#34;, &#34;europe-west1-b&#34;, &#34;europe-west1-c&#34;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [ngfw_enterprise_endpoint_ids](outputs.tf#L28) | The NGFW Enterprise endpoint ids. |  |  |
| [ngfw_enterprise_endpoint_self_links](outputs.tf#L33) | The NGFW Enterprise endpoint self_links. |  |  |
<!-- END TFDOC -->
