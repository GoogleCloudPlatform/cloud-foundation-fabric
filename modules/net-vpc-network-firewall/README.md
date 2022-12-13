# Google Cloud Network Firewall Policy

This module allows creation and management of regional and global network firewall policy :

Yaml abstraction for Firewall rules can simplify users onboarding and also makes rules definition simpler and clearer comparing to HCL.

Nested folder structure for yaml configurations is optionally supported, which allows better and structured code management for multiple teams and environments.

## Example

### Terraform code

```hcl
module "global_policy" { # global firewall rules using YAML by defining rules file location
  source             = "./fabric/modules/project"
  global_policy_name = "global-policy-1"
  project_id         = "my-project"
  global_network     = "my-network"
  deployment_scope   = "global"
  data_folders       = ["./global-rules"]
}

module "global_policy_2" { # global firewall rules using HCL
  source             = "./fabric/modules/project"
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
  source                 = "./fw"
  regional_policy_name   = "regional-policy-1"
  project_id             = "my-project"
  firewall_policy_region = "australia-southeast1"
  deployment_scope       = "regional"
  data_folders           = ["./regional-rules"]
}
# tftest skip
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

<!-- BEGIN_TF_DOCS -->
Copyright 2022 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.40.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 4.40.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.40.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_network_firewall_policy.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network_firewall_policy) | resource |
| [google_compute_network_firewall_policy_association.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network_firewall_policy_association) | resource |
| [google_compute_network_firewall_policy_rule.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network_firewall_policy_rule) | resource |
| [google_compute_region_network_firewall_policy.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_network_firewall_policy) | resource |
| [google_compute_region_network_firewall_policy_association.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_network_firewall_policy_association) | resource |
| [google_compute_region_network_firewall_policy_rule.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_network_firewall_policy_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_data_folders"></a> [data\_folders](#input\_data\_folders) | List of paths to folders where firewall configs are stored in yaml format. Folder may include subfolders with configuration files. Files suffix must be `.yaml`. | `list(string)` | `null` | no |
| <a name="input_deployment_scope"></a> [deployment\_scope](#input\_deployment\_scope) | n/a | `string` | n/a | yes |
| <a name="input_firewall_policy_region"></a> [firewall\_policy\_region](#input\_firewall\_policy\_region) | Network firewall policy region. | `string` | `null` | no |
| <a name="input_firewall_rules"></a> [firewall\_rules](#input\_firewall\_rules) | List rule definitions, default to allow action. | <pre>map(object({<br>    action         = optional(string, "allow")<br>    description    = optional(string, null)<br>    dest_ip_ranges = optional(list(string))<br>    disabled       = optional(bool, false)<br>    direction      = optional(string, "INGRESS")<br>    enable_logging = optional(bool, false)<br>    layer4_configs = optional(list(object({<br>      protocol = string<br>      ports    = optional(list(string))<br>    })), [{ protocol = "all" }])<br>    priority                = optional(number, 1000)<br>    src_secure_tags         = optional(list(string))<br>    src_ip_ranges           = optional(list(string))<br>    target_service_accounts = optional(list(string))<br>    target_secure_tags      = optional(list(string))<br>  }))</pre> | `{}` | no |
| <a name="input_global_network"></a> [global\_network](#input\_global\_network) | VPC SelfLink to attach the global firewall policy. | `string` | `null` | no |
| <a name="input_global_policy_name"></a> [global\_policy\_name](#input\_global\_policy\_name) | Global network firewall policy name. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project id of the project that holds the network. | `string` | n/a | yes |
| <a name="input_regional_network"></a> [regional\_network](#input\_regional\_network) | VPC SelfLink to attach the regional firewall policy. | `string` | `null` | no |
| <a name="input_regional_policy_name"></a> [regional\_policy\_name](#input\_regional\_policy\_name) | Global network firewall policy name. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_global_network_association"></a> [global\_network\_association](#output\_global\_network\_association) | Global association name |
| <a name="output_global_policy_name"></a> [global\_policy\_name](#output\_global\_policy\_name) | Global network firewall policy name |
| <a name="output_global_rules"></a> [global\_rules](#output\_global\_rules) | Global rules. |
| <a name="output_regional_network_association"></a> [regional\_network\_association](#output\_regional\_network\_association) | Global association name |
| <a name="output_regional_policy_name"></a> [regional\_policy\_name](#output\_regional\_policy\_name) | Regional network firewall policy name |
| <a name="output_regional_rules"></a> [regional\_rules](#output\_regional\_rules) | Regional rules. |
<!-- END_TF_DOCS -->