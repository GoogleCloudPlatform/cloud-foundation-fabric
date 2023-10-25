# Google Cloud DNS Response Policy

This module allows management of a [Google Cloud DNS policy and its rules](https://cloud.google.com/dns/docs/zones/manage-response-policies). The policy can already exist and be referenced by name by setting the `policy_create` variable to `false`.

The module also allows setting rules via a factory. An example is given below.

## Examples

### Manage policy and override resolution for specific names

This example shows how to create a policy with a single rule, that directs a specific Google API name to the restricted VIP addresses.

```hcl
module "dns-policy" {
  source     = "./fabric/modules/dns-response-policy"
  project_id = "myproject"
  name       = "googleapis"
  networks = {
    landing = var.vpc.self_link
  }
  rules = {
    pubsub = {
      dns_name = "pubsub.googleapis.com."
      local_data = {
        A = {
          rrdatas = ["199.36.153.4", "199.36.153.5"]
        }
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=simple.yaml
```

### Use existing policy and override resolution via wildcard with exceptions

This example shows how to create a policy with a single rule, that directs all Google API names except specific ones to the restricted VIP addresses.

```hcl
module "dns-policy" {
  source        = "./fabric/modules/dns-response-policy"
  project_id    = "myproject"
  name          = "googleapis"
  policy_create = false
  networks = {
    landing = var.vpc.self_link
  }
  rules = {
    gcr = {
      dns_name = "gcr.io."
      local_data = {
        CNAME = {
          rrdatas = ["restricted.googleapis.com."]
        }
      }
    }
    googleapis-all = {
      dns_name = "*.googleapis.com."
      local_data = {
        CNAME = {
          rrdatas = ["restricted.googleapis.com."]
        }
      }
    }
    pubsub = {
      dns_name = "pubsub.googleapis.com."
    }
    restricted = {
      dns_name = "restricted.googleapis.com."
      local_data = {
        A = {
          rrdatas = [
            "199.36.153.4",
            "199.36.153.5",
            "199.36.153.6",
            "199.36.153.7"
          ]
        }
      }
    }
  }
}
# tftest modules=1 resources=4 inventory=complex.yaml
```

### Define policy rules via a factory file

This example shows how to define rules in a factory file, that mirrors the rules defined via variables in the previous example. Rules defined via the variable are merged with factory rules and take precedence over them when using the same rule names. The YAML syntax closely follows the `rules` variable type.

```hcl
module "dns-policy" {
  source        = "./fabric/modules/dns-response-policy"
  project_id    = "myproject"
  name          = "googleapis"
  policy_create = false
  networks = {
    landing = var.vpc.self_link
  }
  rules_file = "config/rules.yaml"
}
# tftest modules=1 resources=4 files=rules-file inventory=complex.yaml
```

```yaml

---
# Terraform will be unable to decode this file if it does not contain valid YAML
# You can retain `---` (start of the document) to indicate an empty document.

gcr:
  dns_name: "gcr.io."
  local_data:
    CNAME: {rrdatas: ["restricted.googleapis.com."]}
googleapis-all:
  dns_name: "*.googleapis.com."
  local_data:
    CNAME: {rrdatas: ["restricted.googleapis.com."]}
pubsub:
  dns_name: "pubsub.googleapis.com."
restricted:
  dns_name: "restricted.googleapis.com."
  local_data:
    A:
      rrdatas:
        - 199.36.153.4
        - 199.36.153.5
        - 199.36.153.6
        - 199.36.153.7
# tftest-file id=rules-file path=config/rules.yaml
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L30) | Policy name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L49) | Project id for the zone. | <code>string</code> | ✓ |  |
| [clusters](variables.tf#L17) | Map of GKE clusters to which this policy is applied in name => id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L24) | Policy description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [networks](variables.tf#L35) | Map of VPC self links to which this policy is applied in name => self link format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [policy_create](variables.tf#L42) | Set to false to use the existing policy matching name and only manage rules. | <code>bool</code> |  | <code>true</code> |
| [rules](variables.tf#L54) | Map of policy rules in name => rule format. Local data takes precedence over behavior and is in the form record type => attributes. | <code title="map&#40;object&#40;&#123;&#10;  dns_name &#61; string&#10;  behavior &#61; optional&#40;string, &#34;bypassResponsePolicy&#34;&#41;&#10;  local_data &#61; optional&#40;map&#40;object&#40;&#123;&#10;    ttl     &#61; optional&#40;number&#41;&#10;    rrdatas &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [rules_file](variables.tf#L68) | Optional data file in YAML format listing rules that will be combined with those passed in via the `rules` variable. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified policy id. |  |
| [name](outputs.tf#L22) | Policy name. |  |
| [policy](outputs.tf#L27) | Policy resource. |  |

<!-- END TFDOC -->
