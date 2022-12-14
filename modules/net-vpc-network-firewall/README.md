# Google Cloud Network Firewall Policy

This module allows creation and management of regional and global network firewall policy :

Yaml abstraction for Firewall rules can simplify users onboarding and also makes rules definition simpler and clearer comparing to HCL.

Nested folder structure for yaml configurations is optionally supported, which allows better and structured code management for multiple teams and environments.

## Example

### Terraform code

```hcl
module "global_policy" { # global firewall rules using YAML by defining rules file location
  source             = "./fabric/modules/net-vpc-network-firewall"
  global_policy_name = "global-policy-1"
  project_id         = "my-project"
  global_network     = "my-network"
  deployment_scope   = "global"
  data_folders       = ["./firewall-rules"]
}

module "global_policy_2" { # global firewall rules using HCL
  source             = "./fabric/modules/net-vpc-network-firewall"
  global_policy_name = "global-policy-1"
  project_id         = "my-project"
  deployment_scope   = "global"
  firewall_rules = {

      "rule-1" = {
        action         = "allow"
        description    = "rule 2"
        direction      = "INGRESS"
        disabled       = false
        enable_logging = true
        layer4_configs = [{
          ports    = ["8080", "443", "80"]
          protocol = "tcp"
          },
          {
            ports    = ["53", "123-130"]
            protocol = "udp"
          }
        ]
        priority           = 150
        src_ip_ranges      = ["0.0.0.0/0"]
        target_secure_tags = ["516738215535", "839187618417"]
      }

      "rule-2" = {
        action             = "allow"
        description        = "rule 4"
        direction          = "EGRESS"
        disabled           = false
        enable_logging     = true
        target_secure_tags = ["516738215535"]
        dest_ip_ranges     = ["192.168.0.0/24"]
      }
  }
}

module "regional_policy" { # regional firewall rules using YAML by defining rules file location
  source                 = "./fabric/modules/net-vpc-network-firewall"
  regional_policy_name   = "regional-policy-1"
  project_id             = "my-project"
  firewall_policy_region = "australia-southeast1"
  deployment_scope       = "regional"
  data_folders           = ["./firewall-rules"]
}
# tftest modules=3 resources=9 files=rules
```

### Example Configuration Structure using yaml files to create rules

```bash
├── common
│   ├── global-rules.yaml
│   └── regional-rules.yaml
├── dev
│   ├── team-a
│   │   ├── databases.yaml
│   │   └── regional-rules.yaml
│   └── team-b
│       ├── backend.yaml
│       └── frontend.yaml
└── prod
    ├── team-a
    │   ├── regional-rules.yaml
    │   └── webb-app-a.yaml
    └── team-b
        ├── backend.yaml
        └── frontend.yaml
```

### Rule definition format and structure

```yaml
rule-name: # rule descriptive name
  disabled: false #`false` or `true`, FW rule is disabled when `true`, default value is `false`
  description: rule-2 # rules description
  action: allow # allow or deny
  direction: INGRESS # INGRESS or EGRESS
  priority: 1000 # rule priority value, default value is 1000
  enable_logging: true # Enable rule logging. Default is false
  src_secure_tags: ["12345678912", ["98765432198"]] # list of source secure tag
  layer4_configs:
    - protocol: tcp # protocol, put `all` for any protocol
      port: ['443', '80', "140-150"] # ports for a specific protocol, keep empty list `[]` for all ports
  target_service_accounts: # list of target service accounts
  dest_ip_ranges: # list of destination ranges, should be specified only for `EGRESS` rule
  src_ip_ranges: # list of source ranges, should be specified only for `INGRESS` rule
  target_secure_tags: # list of taget secure tag
  ```

Firewall rules example yaml configuration

```yaml
# tftest file rules firewall-rules/rules.yaml
rule-1:
  description: global rule 1
  action: allow
  direction: ingress
  priority: 1000
  enable_logging: true
  layer4_configs:
    - protocol: tcp
      ports:
        - 80
        - 443
    - protocol: udp
      ports:
        - 555
        - 666
  src_ip_ranges:
   - 192.168.1.100/32
   - 10.10.10.0/24
  target_secure_tags:
    - 446253268572
  src_secure_tags:
    - 516738215535
    - 839187618417

rule-2:
  description: global rule 2
  action: allow
  direction: EGRESS
  priority: 1000
  enable_logging: true
  layer4_configs:
    - protocol: tcp
      ports:
        - 80
        - 443
    - protocol: udp
      ports:
        - 555
        - 666
  dest_ip_ranges:
    - 192.168.0.0/24
    - 172.16.10.0/24
  target_secure_tags:
    - 446253268572
  
```
<!-- BEGIN TFDOC -->

## Files

| name | description | resources |
|---|---|---|
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_compute_network_firewall_policy</code> · <code>google_compute_network_firewall_policy_association</code> · <code>google_compute_network_firewall_policy_rule</code> · <code>google_compute_region_network_firewall_policy</code> · <code>google_compute_region_network_firewall_policy_association</code> · <code>google_compute_region_network_firewall_policy_rule</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [deployment_scope](variables.tf#L23) |  | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L75) | Project id of the project that holds the network. | <code>string</code> | ✓ |  |
| [data_folders](variables.tf#L17) | List of paths to folders where firewall configs are stored in yaml format. Folder may include subfolders with configuration files. Files suffix must be `.yaml`. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [firewall_policy_region](variables.tf#L35) | Network firewall policy region. | <code>string</code> |  | <code>null</code> |
| [firewall_rules](variables.tf#L41) | List rule definitions, default to allow action. | <code title="map&#40;object&#40;&#123;&#10;  action         &#61; optional&#40;string, &#34;allow&#34;&#41;&#10;  description    &#61; optional&#40;string, null&#41;&#10;  dest_ip_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;  disabled       &#61; optional&#40;bool, false&#41;&#10;  direction      &#61; optional&#40;string, &#34;INGRESS&#34;&#41;&#10;  enable_logging &#61; optional&#40;bool, false&#41;&#10;  layer4_configs &#61; optional&#40;list&#40;object&#40;&#123;&#10;    protocol &#61; string&#10;    ports    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#91;&#123; protocol &#61; &#34;all&#34; &#125;&#93;&#41;&#10;  priority                &#61; optional&#40;number, 1000&#41;&#10;  src_secure_tags         &#61; optional&#40;list&#40;string&#41;&#41;&#10;  src_ip_ranges           &#61; optional&#40;list&#40;string&#41;&#41;&#10;  target_service_accounts &#61; optional&#40;list&#40;string&#41;&#41;&#10;  target_secure_tags      &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [global_network](variables.tf#L64) | VPC SelfLink to attach the global firewall policy. | <code>string</code> |  | <code>null</code> |
| [global_policy_name](variables.tf#L69) | Global network firewall policy name. | <code>string</code> |  | <code>null</code> |
| [regional_network](variables.tf#L80) | VPC SelfLink to attach the regional firewall policy. | <code>string</code> |  | <code>null</code> |
| [regional_policy_name](variables.tf#L85) | Global network firewall policy name. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [global_network_association](outputs.tf#L17) | Global association name |  |
| [global_policy_name](outputs.tf#L27) | Global network firewall policy name |  |
| [global_rules](outputs.tf#L22) | Global rules. |  |
| [regional_network_association](outputs.tf#L32) | Global association name |  |
| [regional_policy_name](outputs.tf#L42) | Regional network firewall policy name |  |
| [regional_rules](outputs.tf#L37) | Regional rules. |  |

<!-- END TFDOC -->
