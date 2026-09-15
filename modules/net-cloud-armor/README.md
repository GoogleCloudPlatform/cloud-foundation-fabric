# Cloud Armor Security Policy

This module provisions and configures [Cloud Armor security policies](https://cloud.google.com/armor/docs/security-policy-overview) along with their rules. It handles both global and regional policies through a unified interface, validating at plan time that all requested features are compatible with the selected policy scope and type.

Attach the policy to load balancers using the `id` output, which can be passed to the `security_policy` attribute of backend services managed by the `net-lb-app-ext`, `net-lb-app-ext-regional`, `net-lb-app-int` and `net-lb-ext` modules, or to the `edge_security_policy` attribute of backend buckets managed by `net-lb-app-ext`. Regional external passthrough Network Load Balancers managed by `net-lb-ext` only accept network edge policies of type `CLOUD_ARMOR_NETWORK`. Cloud Armor also protects global external proxy Network Load Balancers via backend policies, for which no module exists. Cross-region internal Application Load Balancers, internal proxy Network Load Balancers, and internal passthrough Network Load Balancers do not support Cloud Armor.

The baseline rule at priority `2147483647` is always managed by the module via the `default_rule_config` variable and cannot be defined in `rules`.

Rules are keyed by name in Terraform state, while the API identifies them by priority. Renaming a rule without changing its priority plans a create and a destroy for the same API resource, so use a `moved` block for renames, or change the priority at the same time.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Global backend policy](#global-backend-policy)
  - [Rate limiting and redirects](#rate-limiting-and-redirects)
  - [Adaptive Protection](#adaptive-protection)
  - [Regional backend policy](#regional-backend-policy)
  - [Network edge policy](#network-edge-policy)
  - [Edge policy for backend buckets](#edge-policy-for-backend-buckets)
  - [Rules factory](#rules-factory)
- [Scope and type support matrix](#scope-and-type-support-matrix)
- [Recipes](#recipes)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

### Global backend policy

Global backend security policy for the global external Application Load Balancer, featuring preconfigured WAF rules, rule exclusions, an IP allowlist, and request header injection.

```hcl
module "cloud-armor" {
  source     = "./fabric/modules/net-cloud-armor"
  project_id = var.project_id
  name       = "waf-global"
  default_rule_config = {
    action = "deny(403)"
  }
  advanced_options_config = {
    json_parsing = "STANDARD"
    log_level    = "VERBOSE"
  }
  rules = {
    allow-health-checks = {
      priority = 10
      action   = "allow"
      match = {
        src_ip_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
      }
    }
    owasp-sqli = {
      priority = 1000
      action   = "deny(403)"
      match = {
        expression = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})"
      }
      preconfigured_waf_config = {
        exclusions = [{
          target_rule_set = "sqli-v33-stable"
          target_rule_ids = ["owasp-crs-v030301-id942100-sqli"]
          request_uris = [{
            operator = "STARTS_WITH"
            value    = "/api/internal"
          }]
        }]
      }
    }
    owasp-xss = {
      priority = 1001
      action   = "deny(403)"
      preview  = true
      match = {
        expression = "evaluatePreconfiguredWaf('xss-v33-stable')"
      }
    }
    geo-block = {
      priority = 2000
      action   = "deny(403)"
      match = {
        expression = "origin.region_code != 'IT'"
      }
      header_action = {
        x-blocked-by = "cloud-armor"
      }
    }
  }
}
# tftest modules=1 resources=6 inventory=global.yaml
```

### Rate limiting and redirects

Traffic throttling, multi-key rate-based bans, and reCAPTCHA redirection are configured through the `rate_limit_options` and `redirect_options` rule attributes.

```hcl
module "cloud-armor" {
  source     = "./fabric/modules/net-cloud-armor"
  project_id = var.project_id
  name       = "rate-limit"
  recaptcha_options_config = {
    redirect_site_key = "6LcXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  }
  rules = {
    throttle = {
      priority = 100
      action   = "throttle"
      match = {
        src_ip_ranges = ["*"]
      }
      rate_limit_options = {
        exceed_action  = "deny(429)"
        enforce_on_key = "IP"
        rate_limit_threshold = {
          count        = 100
          interval_sec = 60
        }
      }
    }
    ban-login = {
      priority = 200
      action   = "rate_based_ban"
      match = {
        expression = "request.path.matches('/login')"
      }
      rate_limit_options = {
        exceed_action    = "deny(403)"
        ban_duration_sec = 600
        ban_threshold = {
          count        = 50
          interval_sec = 60
        }
        enforce_on_key_configs = [
          { type = "XFF_IP" },
          { type = "HTTP_HEADER", name = "x-api-key" }
        ]
        rate_limit_threshold = {
          count        = 10
          interval_sec = 60
        }
      }
    }
    recaptcha = {
      priority = 300
      action   = "redirect"
      match = {
        expression = "request.path.matches('/signup')"
      }
      redirect_options = {
        type = "GOOGLE_RECAPTCHA"
      }
    }
  }
}
# tftest modules=1 resources=5 inventory=rate-limit.yaml
```

### Adaptive Protection

Adaptive Protection detects and mitigates Layer 7 DDoS attacks on global `CLOUD_ARMOR` policies. Cloud Armor Standard receives basic alerts, while attack signatures, suggested rules and automatic deployment require Cloud Armor Enterprise. Granular detection thresholds can be defined via `threshold_configs`.

```hcl
module "cloud-armor" {
  source     = "./fabric/modules/net-cloud-armor"
  project_id = var.project_id
  name       = "adaptive"
  adaptive_protection_config = {
    layer_7_ddos_defense = {
      rule_visibility = "STANDARD"
      threshold_configs = {
        api = {
          auto_deploy_confidence_threshold = 0.8
          auto_deploy_expiration_sec       = 3600
          traffic_granularity_configs = [{
            type  = "HTTP_PATH"
            value = "/api"
          }]
        }
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=adaptive.yaml
```

### Regional backend policy

Defining `region` creates a regional policy for attachment to backend services of regional external and internal Application Load Balancers. Features available only globally (`redirect`, `header_action`, Adaptive Protection, reCAPTCHA) are rejected at plan time.

```hcl
module "cloud-armor" {
  source     = "./fabric/modules/net-cloud-armor"
  project_id = var.project_id
  region     = "europe-west1"
  name       = "waf-regional"
  default_rule_config = {
    action = "deny(403)"
  }
  rules = {
    allow-corp = {
      priority = 100
      action   = "allow"
      match = {
        src_ip_ranges = ["192.0.2.0/24"]
      }
    }
    owasp-rce = {
      priority = 1000
      action   = "deny(403)"
      match = {
        expression = "evaluatePreconfiguredWaf('rce-v33-stable')"
      }
    }
  }
}
# tftest modules=1 resources=4 inventory=regional.yaml
```

### Network edge policy

Regional policies configured with type `CLOUD_ARMOR_NETWORK` safeguard external passthrough Network Load Balancers, relying on `network_match` (layer 3/4 attributes and user-defined fields) rather than `match`. Rules only support the `allow` and `deny` actions. Cloud Armor Enterprise is required to create a `CLOUD_ARMOR_NETWORK` policy at all: on lower service tiers the API rejects the policy itself with `Network Security Policies are not supported as part of the current Cloud Armor service tier`. Attaching one additionally requires regional advanced network DDoS protection, which is configured through a separate `CLOUD_ARMOR_NETWORK` policy setting `ddos_protection` and no rules, attached to a network edge security service. The module rejects policies combining `ddos_protection` and rules.

```hcl
module "cloud-armor" {
  source     = "./fabric/modules/net-cloud-armor"
  project_id = var.project_id
  region     = "europe-west1"
  name       = "network-edge"
  type       = "CLOUD_ARMOR_NETWORK"
  default_rule_config = {
    action = "deny"
  }
  user_defined_fields = {
    sig1 = {
      base   = "UDP"
      offset = 8
      size   = 2
      mask   = "0x8F00"
    }
  }
  rules = {
    allow-dns = {
      priority = 100
      action   = "allow"
      network_match = {
        dest_ports   = ["53"]
        ip_protocols = ["udp"]
        user_defined_fields = {
          sig1 = ["0x8F00"]
        }
      }
    }
    deny-regions = {
      priority = 200
      action   = "deny"
      network_match = {
        src_region_codes = ["XX"]
      }
    }
  }
}
# tftest modules=1 resources=4 inventory=network.yaml
```

### Edge policy for backend buckets

Edge security policies filter traffic before reaching Cloud CDN and serve as the only policy type that can be associated with backend buckets via the `edge_security_policy` attribute.

```hcl
module "cloud-armor" {
  source     = "./fabric/modules/net-cloud-armor"
  project_id = var.project_id
  name       = "edge"
  type       = "CLOUD_ARMOR_EDGE"
  rules = {
    deny-regions = {
      priority = 100
      action   = "deny(403)"
      match = {
        expression = "origin.region_code == 'XX'"
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=edge.yaml
```

### Rules factory

Rules may be defined in an external YAML file matching the [rules schema](./schemas/rules.schema.md), which the module automatically combines with rules supplied in the `rules` variable. Rules from the `rules` variable take precedence when the same key is defined in both, and priorities must be unique across both sources. All plan-time consistency checks apply to factory rules too.

```hcl
module "cloud-armor" {
  source     = "./fabric/modules/net-cloud-armor"
  project_id = var.project_id
  name       = "waf-factory"
  factories_config = {
    rules_file_path = "configs/rules.yaml"
  }
  rules = {
    allow-corp = {
      priority = 10
      action   = "allow"
      match = {
        src_ip_ranges = ["192.0.2.0/24"]
      }
    }
  }
}
# tftest modules=1 resources=5 files=rules inventory=factory.yaml
```

```yaml
# yaml-language-server: $schema=../schemas/rules.schema.json

owasp-sqli:
  priority: 1000
  action: deny(403)
  match:
    expression: evaluatePreconfiguredWaf('sqli-v33-stable')
  preconfigured_waf_config:
    exclusions:
      - target_rule_set: sqli-v33-stable
        request_query_params:
          - operator: EQUALS
            value: description
throttle:
  priority: 2000
  action: throttle
  match:
    src_ip_ranges:
      - "*"
  rate_limit_options:
    exceed_action: deny(429)
    enforce_on_key: IP
    rate_limit_threshold:
      count: 100
      interval_sec: 60
# tftest-file id=rules path=configs/rules.yaml schema=rules.schema.json
```

## Scope and type support matrix

| Feature | Global `CLOUD_ARMOR` | Global `CLOUD_ARMOR_EDGE` | Global `CLOUD_ARMOR_INTERNAL_SERVICE` | Regional `CLOUD_ARMOR` | Regional `CLOUD_ARMOR_NETWORK` |
|---|:---:|:---:|:---:|:---:|:---:|
| Attachment | global external ALB backend services (`net-lb-app-ext`), global external proxy NLB (no module) | global external ALB backend buckets (`net-lb-app-ext`) and CDN-enabled backend services (not exposed by the module) | Cloud Service Mesh endpoint policies | regional external ALB (`net-lb-app-ext-regional`), regional internal ALB (`net-lb-app-int`) | regional external passthrough NLB (`net-lb-ext`) |
| `match` (IP ranges, CEL expressions) | ✓ | ✓ (subset of attributes) | ✓ | ✓ | |
| `network_match`, `user_defined_fields`, `ddos_protection` | | | | | ✓ |
| `allow`, `deny` actions | ✓ | ✓ | ✓ | ✓ | ✓ (no status code) |
| `throttle`, `rate_based_ban` actions, `preconfigured_waf_config` | ✓ | | | ✓ | |
| `redirect` action, `header_action`, `exceed_redirect_options`, `recaptcha_options` | ✓ | | | | |
| `adaptive_protection_config`, `recaptcha_options_config` | ✓ | | | | |
| `labels` | ✓ | ✓ | ✓ | | |

Incompatible feature and policy combinations fail validation at plan time.

Edge policy expressions depend on the attachment target, and the API enforces the distinction at rule creation rather than at attach time. Policies destined for Media CDN evaluate `origin.asn`, `origin.ip`, `origin.region_code`, `request.headers`, `request.method`, `request.path`, `request.query` and `request.scheme`. Policies attached to backend buckets of a global external Application Load Balancer only evaluate `origin.ip` (via `src_ip_ranges` or `inIpRange`) and `origin.region_code`; any other attribute is rejected with `Expression supported only for Media CDN edge policies`. The module cannot tell the two targets apart, so it does not validate this at plan time.

Internal service policies are in preview and their `fairshare` action is not available in the provider, so they are limited to `allow` and `deny` rules.

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Recipes

- [Global external Application Load Balancer with Cloud Armor WAF and edge policies](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master/modules/net-cloud-armor/recipe-glb-waf)
- [Regional Application Load Balancers with a shared Cloud Armor policy](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master/modules/net-cloud-armor/recipe-regional-waf)

## Files

| name | description | resources |
|---|---|---|
| [factory.tf](./factory.tf) | Rules factory. |  |
| [global.tf](./global.tf) | Global security policy and rules. | <code>google_compute_security_policy</code> · <code>google_compute_security_policy_rule</code> |
| [main.tf](./main.tf) | Module-level locals and resources. |  |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [regional.tf](./regional.tf) | Regional security policy and rules. | <code>google_compute_region_security_policy</code> · <code>google_compute_region_security_policy_rule</code> |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L154) | Policy name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L160) | Project id where the policy will be created. | <code>string</code> | ✓ |  |
| [adaptive_protection_config](variables.tf#L17) | Adaptive Protection configuration. Only supported by global CLOUD_ARMOR policies. Cloud Armor Standard only receives basic alerts, attack signatures and suggested rules require Cloud Armor Enterprise. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [advanced_options_config](variables.tf#L61) | Advanced options configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [ddos_protection](variables.tf#L102) | DDoS protection level. Only supported by regional policies of type CLOUD_ARMOR_NETWORK. | <code>string</code> |  | <code>null</code> |
| [default_rule_config](variables.tf#L115) | Configuration for the default rule with lowest priority, which is always present in a policy. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L132) | Policy description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [factories_config](variables.tf#L138) | Paths to data files and folders that enable factory functionality. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L147) | Policy labels. Only supported by global policies. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [recaptcha_options_config](variables.tf#L166) | reCAPTCHA configuration options. Only supported by global CLOUD_ARMOR policies. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [region](variables.tf#L174) | Policy region. Leave null or set to 'global' for a global policy. | <code>string</code> |  | <code>null</code> |
| [rules](variables.tf#L180) | Policy rules, merged with factory rules. Use `match` for CLOUD_ARMOR, CLOUD_ARMOR_EDGE and CLOUD_ARMOR_INTERNAL_SERVICE policies, `network_match` for CLOUD_ARMOR_NETWORK policies. Consistency with the policy scope and type is checked at plan time. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [type](variables.tf#L336) | Policy type. Global policies support CLOUD_ARMOR, CLOUD_ARMOR_EDGE and CLOUD_ARMOR_INTERNAL_SERVICE, regional policies support CLOUD_ARMOR and CLOUD_ARMOR_NETWORK. Rules for types other than CLOUD_ARMOR only support the 'allow' and 'deny' actions. | <code>string</code> |  | <code>&#34;CLOUD_ARMOR&#34;</code> |
| [user_defined_fields](variables.tf#L353) | User-defined fields for CLOUD_ARMOR_NETWORK policies, keyed by field name. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified security policy id. |  |
| [name](outputs.tf#L32) | Security policy name. |  |
| [self_link](outputs.tf#L41) | Security policy self link. |  |
<!-- END TFDOC -->
