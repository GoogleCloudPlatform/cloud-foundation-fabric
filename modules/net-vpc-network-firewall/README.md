# Google Cloud Network Firewall Policy

This module allows creation and management of regional and global network firewall policy :

Yaml abstraction for FW rules can simplify users onboarding and also makes rules definition simpler and clearer comparing to HCL.

Nested folder structure for yaml configurations is optionally supported, which allows better and structured code management for multiple teams and environments.

## Example

### Terraform code

```hcl
module "global_policy_1" { # firewall rules using yaml configuration
  source             = "./fw_module"
  project_id         = "project_id"
  global_policy_name = "policy-1"
  global_network     = "vpc_SelfLink"
  parent_tag         = "tagKeys/123456789012"
  data_folders       = ["./global-policies"]
}

module "global_policy_2" { # firewall rules using firewall_rules variables
  source             = "./fw_module"
  project_id         = "project_id"
  global_policy_name = "policy-2"
  parent_tag         = "tagKeys/123456789012"
  firewall_rules = {
    rule-1 = {
      deployment              = "global"
      disabled                = false
      description             = "rule 1"
      action                  = "allow"
      direction               = "INGRESS"
      priority                = 999
      enable_logging          = true
      src_secure_tags         = ["production", "nonprod"]
      ip_protocol             = "tcp"
      ports                   = ["8080", "80", "443"]
      src_ip_ranges           = ["192.168.0.0/24", "192.168.1.0/24"]
      target_secure_tags      = ["nonprod", "preprod"]

    }
    rule-2 = {
      deployment              = "global"
      disabled                = false
      description             = "rule 1"
      action                  = "allow"
      direction               = "INGRESS"
      priority                = 999
      enable_logging          = true
      src_secure_tags         = ["production", "nonprod"]
      ip_protocol             = "tcp"
      ports                   = ["8080", "80", "443"]
      src_ip_ranges           = ["192.168.0.0/24", "192.168.1.0/24"]
      target_secure_tags      = ["nonprod", "preprod"]

    }
  }
}

module "regional_policy_1" { # firewall rules using yaml configuration
  source                 = "./fw_module"
  project_id             = "project_id"
  regional_policy_name   = "policy-3"
  regional_network       = "vpc_SelfLink"
  parent_tag             = "tagKeys/123456789012"
  firewall_policy_region = "australia-southeast1"
  data_folders           = ["./regional-policies"]
}
# tftest skip
```

### Example Configuration Structure using yaml files to create rules

```bash
├── common
│   ├── default-rules.yaml
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
rule-name: # descriptive name, naming convention is adjusted by the module
  deployment: deployment option "regional" or "global"
  disabled: #`false` or `true`, FW rule is disabled when `true`, default value is `false`
  description: # rules description
  action: # allow or deny
  direction: # INGRESS or EGRESS
  priority: # rule priority value, default value is 1000
  enable_logging: # Enable rule logging. Default is false
  src_secure_tags: # list of security tag source
  ip_protocol: #  protocol, put `all` for any protocol
  ports: # list of ports
  target_service_accounts: #  list of target service accounts
  dest_ip_ranges: # Destination ip range
  src_ip_ranges: # source ip range
  target_secure_tags: list tag security tags target
  ```

Firewall rules example yaml configuration

```yaml
rule-1:
  deployment: global
  description: global rule 1
  action: allow
  direction: ingress
  priority: 100
  enable_logging: true
  ip_protocol: tcp
  ports:
    - 8080
    - 123-345
    - 22

  src_ip_ranges:
   - 192.168.1.100/32
   - 10.10.10.0/24

  target_secure_tags:
    - nonprod
    - preprod

  src_secure_tags:
    - production
    - nonprod
```

<!-- BEGIN_TF_DOCS -->
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
| [google_tags_tag_value.src_secure_tags](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/tags_tag_value) | data source |
| [google_tags_tag_value.target_secure_tags](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/tags_tag_value) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_data_folders"></a> [data\_folders](#input\_data\_folders) | List of paths to folders where firewall configs are stored in yaml format. Folder may include subfolders with configuration files. Files suffix must be `.yaml`. | `list(string)` | `null` | no |
| <a name="input_firewall_policy_region"></a> [firewall\_policy\_region](#input\_firewall\_policy\_region) | Network firewall policy region. | `string` | `null` | no |
| <a name="input_firewall_rules"></a> [firewall\_rules](#input\_firewall\_rules) | List rule definitions, default to allow action. | <pre>map(object({<br>    deployment              = optional(string, "global")<br>    disabled                = optional(bool, false)<br>    description             = optional(string)<br>    action                  = optional(string, "allow")<br>    direction               = optional(string, "INGRESS")<br>    priority                = optional(number, 1000)<br>    enable_logging          = optional(bool, false)<br>    src_secure_tags         = optional(list(string))<br>    ip_protocol             = optional(string, "all")<br>    ports                   = optional(list(string))<br>    target_service_accounts = optional(list(string))<br>    dest_ip_ranges          = optional(list(string))<br>    src_ip_ranges           = optional(list(string))<br>    target_secure_tags      = optional(list(string))<br><br><br>  }))</pre> | `{}` | no |
| <a name="input_global_network"></a> [global\_network](#input\_global\_network) | VPC SelfLink to attach the global firewall policy. | `string` | `null` | no |
| <a name="input_global_policy_name"></a> [global\_policy\_name](#input\_global\_policy\_name) | Global network firewall policy name. | `string` | `null` | no |
| <a name="input_parent_tag"></a> [parent\_tag](#input\_parent\_tag) | An identifier for the resource with format tagValues/{{name}} | `string` | `"null"` | no |
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