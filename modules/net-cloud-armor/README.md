# Google Cloud Armor Security Policy Module

This module manages a Google Cloud Armor security policy, including preconfigured WAF (OWASP) rules, IP allow/deny rules, rate limiting, and Layer 7 DDoS Adaptive Protection.

<!-- BEGIN TOC -->
- [Basic Usage](#basic-usage)
- [Rate Limiting and Adaptive Protection](#rate-limiting-and-adaptive-protection)
- [Rules Factory](#rules-factory)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Basic Usage

```hcl
module "cloud_armor" {
  source     = "./fabric/modules/net-cloud-armor"
  project_id = var.project_id
  name       = "my-security-policy"
  rules = {
    owasp-sqli = {
      action            = "deny(403)"
      priority          = 1000
      description       = "OWASP SQL Injection protection"
      preconfigured_waf = "sqli-v33-stable"
    }
    allow-trusted-ips = {
      action        = "allow"
      priority      = 2000
      description   = "Allow corporate IPs"
      src_ip_ranges = ["192.0.2.0/24"]
    }
  }
}
# tftest modules=1 resources=1
```

## Rate Limiting and Adaptive Protection

```hcl
module "cloud_armor" {
  source     = "./fabric/modules/net-cloud-armor"
  project_id = var.project_id
  name       = "advanced-security-policy"
  adaptive_protection_config = {
    layer_7_ddos_defense = {
      enable          = true
      rule_visibility = "STANDARD"
    }
  }
  rules = {
    rate-limit = {
      action        = "throttle"
      priority      = 5000
      description   = "Rate limit traffic"
      src_ip_ranges = ["*"]
      rate_limit_options = {
        conform_action = "allow"
        exceed_action  = "deny(429)"
        enforce_on_key = "IP"
        rate_limit_threshold = {
          count        = 100
          interval_sec = 60
        }
      }
    }
  }
}
# tftest modules=1 resources=1
```

## Rules Factory

The module includes a rules factory for massive creation of rules leveraging YAML configuration files. Each configuration file can contain rules conforming to the schema defined in [`schemas/rules.schema.json`](schemas/rules.schema.json).

```hcl
module "cloud_armor" {
  source     = "./fabric/modules/net-cloud-armor"
  project_id = var.project_id
  name       = "waf-security-policy"
  factories_config = {
    rules_file_path = "rules/owasp.yaml"
  }
}
# tftest modules=1 resources=1 files=waf_rules
```

```yaml
# yaml-language-server: $schema=../schemas/rules.schema.json

owasp-sqli:
  action: deny(403)
  priority: 1000
  description: OWASP SQL injection protection
  preconfigured_waf: sqli-v33-stable

owasp-xss:
  action: deny(403)
  priority: 1001
  description: OWASP XSS protection
  preconfigured_waf: xss-v33-stable

threat-intel-tor:
  action: deny(403)
  priority: 1050
  description: Block Tor exit nodes
  threat_intel_feed: iplist-tor-exit-nodes

geo-block-non-us:
  action: deny(403)
  priority: 1100
  description: Deny non-US traffic
  expression: origin.region_code != 'US'

allow-gcp-health-checks:
  action: allow
  priority: 10
  description: Allow GCP health check probes
  src_ip_ranges:
    - 130.211.0.0/22
    - 35.191.0.0/16
# tftest-file id=waf_rules path=rules/owasp.yaml schema=rules.schema.json
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L92) | The name of the security policy. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L97) | The project in which the security policy belongs. | <code>string</code> | ✓ |  |
| [adaptive_protection_config](variables.tf#L15) | Adaptive Protection configuration for this security policy. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [advanced_options_config](variables.tf#L41) | Advanced options configuration for this security policy. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [default_rule_action](variables.tf#L55) | Action for the default rule (priority 2147483647). | <code>string</code> |  | <code>&#34;allow&#34;</code> |
| [default_rule_description](variables.tf#L65) | Description for the default rule (priority 2147483647). | <code>string</code> |  | <code>&#34;Default rule.&#34;</code> |
| [description](variables.tf#L71) | An optional description of this security policy. | <code>string</code> |  | <code>&#34;Managed by Terraform.&#34;</code> |
| [factories_config](variables.tf#L77) | Paths to rule data definitions. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L86) | Labels to apply to the security policy. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [recaptcha_options_config](variables.tf#L102) | reCAPTCHA configuration options for this security policy. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [rules](variables.tf#L110) | Security policy rules. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [type](variables.tf#L150) | The type indicates the intended use of the security policy (CLOUD_ARMOR or CLOUD_ARMOR_EDGE). | <code>string</code> |  | <code>&#34;CLOUD_ARMOR&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [fingerprint](outputs.tf#L15) | Fingerprint of the security policy. |  |
| [id](outputs.tf#L20) | The security policy ID. |  |
| [name](outputs.tf#L25) | The security policy name. |  |
| [security_policy](outputs.tf#L30) | The security policy resource. |  |
| [self_link](outputs.tf#L35) | The URI of the created security policy. |  |
<!-- END TFDOC -->
