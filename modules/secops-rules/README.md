# SecOps Rules

This module allows creation and management of [custom rules](https://cloud.google.com/chronicle/docs/detection/view-all-rules) as well as [reference lists](https://cloud.google.com/chronicle/docs/reference/reference-lists) in Google SecOps.

- rule definition (yaral code) and reference list entries are managed as files in data folder as per the `factories_config` variable and sample code
- rule and reference list deployments can leverage both `rules_config` and `reference_lists_config` variables or YAML file still specified in the `factories_config` variable.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Sample SecOps Rules and reference list deployment](#sample-secops-rules-and-reference-list-deployment)
  - [SecOps Rules Factory](#secops-rules-factory)
- [Variables](#variables)
<!-- END TOC -->

## Examples

### Sample SecOps Rules and reference list deployment

This is a sample usage of the secops-rules module for deploying a rule (network_traffic_to_specific_country) and a reference list (private_ip_ranges), definition of the rule in yaral is available in the corresponding file in the `data/rules` folder and the reference list in the `data/reference_lists` folder. Deployment configuration for both is passed as an input to the module using the `rules_config` and `reference_lists_config` variables.

```hcl
module "secops" {
  source        = "./fabric/modules/secops-rules"
  project_id    = var.project_id
  tenant_config = var.secops_tenant_config
  reference_lists_config = {
    "private_ip_ranges" = {
      description = "Private CIDR ranges"
      type        = "CIDR"
    }
  }
  rules_config = {
    "network_traffic_to_specific_country" = {
      enabled       = true
      alerting      = true
      archived      = false
      run_frequency = "LIVE"
    }
  }
  factories_config = {
    rules_defs           = "./data/rules"
    reference_lists_defs = "./data/reference_lists"
  }
}
# tftest modules=1 resources=3 files=reference,rule inventory=basic.yaml
```

```
rule network_traffic_to_specific_country {

meta:
  author = "Google Cloud Security"
  description = "Identify network traffic based on target country"
  type = "alert"
  tags = "geoip enrichment"
  data_source = "microsoft windows events"
  severity = "Low"
  priority = "Low"

events:
  $network.metadata.event_type = "NETWORK_CONNECTION"
  //Specify a country of interest to monitor or add additional countries using an or statement
  $network.target.ip_geo_artifact.location.country_or_region = "France" nocase
  $network.target.ip = $ip

match:
  $ip over 30m

outcome:
  $risk_score = max(35)
  $event_count = count_distinct($network.metadata.id)

  // added to populate alert graph with additional context
  $principal_ip = array_distinct($network.principal.ip)

  // Commented out target.ip because it is already represented in graph as match variable. If match changes, can uncomment to add to results
  //$target_ip = array_distinct($network.target.ip)
  $principal_process_pid = array_distinct($network.principal.process.pid)
  $principal_process_command_line = array_distinct($network.principal.process.command_line)
  $principal_process_file_sha256 = array_distinct($network.principal.process.file.sha256)
  $principal_process_file_full_path = array_distinct($network.principal.process.file.full_path)
  $principal_process_product_specfic_process_id = array_distinct($network.principal.process.product_specific_process_id)
  $principal_process_parent_process_product_specfic_process_id = array_distinct($network.principal.process.parent_process.product_specific_process_id)
  $target_process_pid = array_distinct($network.target.process.pid)
  $target_process_command_line = array_distinct($network.target.process.command_line)
  $target_process_file_sha256 = array_distinct($network.target.process.file.sha256)
  $target_process_file_full_path = array_distinct($network.target.process.file.full_path)
  $target_process_product_specfic_process_id = array_distinct($network.target.process.product_specific_process_id)
  $target_process_parent_process_product_specfic_process_id = array_distinct($network.target.process.parent_process.product_specific_process_id)
  $principal_user_userid = array_distinct($network.principal.user.userid)
  $target_user_userid = array_distinct($network.target.user.userid)

condition:
  $network
}
# tftest-file id=rule path=data/rules/network_traffic_to_specific_country.yaral
```

```
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
127.0.0.1/32
::1/128
fc00::/7
fe80::/10
# tftest-file id=reference path=data/reference_lists/private_ip_ranges.txt
```

### SecOps Rules Factory

The module includes a secops rules and reference list factory for the configuration of rules and reference lists leveraging YAML configuration files. Each configuration file for rules and reference lists contains more than one rule with a structure that reflects the `rules_config` and `reference_lists_config` variables. Again rules and reference list definition is available in the corresponding yaral and txt files in the data folder.

```hcl
module "secops" {
  source        = "./fabric/modules/secops-rules"
  project_id    = var.project_id
  tenant_config = var.secops_tenant_config
  factories_config = {
    rules                = "./secops_rules.yaml"
    rules_defs           = "./data/rules"
    reference_lists      = "./secops_reference_lists.yaml"
    reference_lists_defs = "./data/reference_lists"
  }
}
# tftest modules=1 resources=3 files=1,2,reference,rule inventory=factory.yaml

```

```yaml
network_traffic_to_specific_country:
  enabled: true
  alerting: true
  archived: false
  run_frequency: "DAILY"
# tftest-file id=1 path=secops_rules.yaml
```

```yaml
private_ip_ranges:
  description: "Private CIDR ranges"
  type: CIDR # either CIDR, STRING, REGEX
# tftest-file id=2 path=secops_reference_lists.yaml
```

```
rule network_traffic_to_specific_country {

meta:
  author = "Google Cloud Security"
  description = "Identify network traffic based on target country"
  type = "alert"
  tags = "geoip enrichment"
  data_source = "microsoft windows events"
  severity = "Low"
  priority = "Low"

events:
  $network.metadata.event_type = "NETWORK_CONNECTION"
  //Specify a country of interest to monitor or add additional countries using an or statement
  $network.target.ip_geo_artifact.location.country_or_region = "France" nocase
  $network.target.ip = $ip

match:
  $ip over 30m

outcome:
  $risk_score = max(35)
  $event_count = count_distinct($network.metadata.id)

  // added to populate alert graph with additional context
  $principal_ip = array_distinct($network.principal.ip)

  // Commented out target.ip because it is already represented in graph as match variable. If match changes, can uncomment to add to results
  //$target_ip = array_distinct($network.target.ip)
  $principal_process_pid = array_distinct($network.principal.process.pid)
  $principal_process_command_line = array_distinct($network.principal.process.command_line)
  $principal_process_file_sha256 = array_distinct($network.principal.process.file.sha256)
  $principal_process_file_full_path = array_distinct($network.principal.process.file.full_path)
  $principal_process_product_specfic_process_id = array_distinct($network.principal.process.product_specific_process_id)
  $principal_process_parent_process_product_specfic_process_id = array_distinct($network.principal.process.parent_process.product_specific_process_id)
  $target_process_pid = array_distinct($network.target.process.pid)
  $target_process_command_line = array_distinct($network.target.process.command_line)
  $target_process_file_sha256 = array_distinct($network.target.process.file.sha256)
  $target_process_file_full_path = array_distinct($network.target.process.file.full_path)
  $target_process_product_specfic_process_id = array_distinct($network.target.process.product_specific_process_id)
  $target_process_parent_process_product_specfic_process_id = array_distinct($network.target.process.parent_process.product_specific_process_id)
  $principal_user_userid = array_distinct($network.principal.user.userid)
  $target_user_userid = array_distinct($network.target.user.userid)

condition:
  $network
}
# tftest-file id=rule path=data/rules/network_traffic_to_specific_country.yaral
```

```
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
127.0.0.1/32
::1/128
fc00::/7
fe80::/10
# tftest-file id=reference path=data/reference_lists/private_ip_ranges.txt
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L29) | Project used for resources. | <code>string</code> | ✓ |  |
| [tenant_config](variables.tf#L66) | SecOps Tenant configuration. | <code title="object&#40;&#123;&#10;  customer_id &#61; string&#10;  region      &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [factories_config](variables.tf#L17) | Paths to  YAML config expected in 'rules' and 'reference_lists'. Path to folders containing rules definitions (yaral files) and reference lists content (txt files) for the corresponding _defs keys. | <code title="object&#40;&#123;&#10;  rules                &#61; optional&#40;string&#41;&#10;  rules_defs           &#61; optional&#40;string, &#34;data&#47;rules&#34;&#41;&#10;  reference_lists      &#61; optional&#40;string&#41;&#10;  reference_lists_defs &#61; optional&#40;string, &#34;data&#47;reference_lists&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [reference_lists_config](variables.tf#L34) | SecOps Reference lists configuration. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; string&#10;  type        &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [rules_config](variables.tf#L49) | SecOps Detection rules configuration. | <code title="map&#40;object&#40;&#123;&#10;  enabled  &#61; optional&#40;bool, true&#41;&#10;  alerting &#61; optional&#40;bool, false&#41;&#10;  archived &#61; optional&#40;bool, false&#41;&#10;  run_frequency : optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
<!-- END TFDOC -->
