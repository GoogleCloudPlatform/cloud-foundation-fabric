# Google Cloud DNS Response Policy

This module allows management of a [Google Cloud DNS policy and its rules](https://cloud.google.com/dns/docs/zones/manage-response-policies). The policy can already exist and be referenced by name by setting the `policy_create` variable to `false`.

The module also allows setting rules via a factory. An example is given below.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Manage policy and override resolution for specific names](#manage-policy-and-override-resolution-for-specific-names)
  - [Use existing policy and override resolution via wildcard with exceptions](#use-existing-policy-and-override-resolution-via-wildcard-with-exceptions)
  - [Define policy rules via a factory file](#define-policy-rules-via-a-factory-file)
  - [Context](#context)
- [Variables](#variables)
- [Outputs](#outputs)
- [Fixtures](#fixtures)
<!-- END TOC -->

## Examples

### Manage policy and override resolution for specific names

This example shows how to create a policy with a single rule, that directs a specific Google API name to the restricted VIP addresses.

```hcl
module "dns-policy" {
  source     = "./fabric/modules/dns-response-policy"
  project_id = var.project_id
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
# tftest modules=1 resources=2 inventory=simple.yaml e2e
```

### Use existing policy and override resolution via wildcard with exceptions

This example shows how to create a policy with a single rule, that directs all Google API names except specific ones to the restricted VIP addresses.

```hcl
module "dns-policy" {
  source        = "./fabric/modules/dns-response-policy"
  project_id    = var.project_id
  name          = module.dns-response-policy.name
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
# tftest modules=2 resources=5 fixtures=fixtures/dns-response-policy.tf inventory=complex.yaml e2e
```

### Define policy rules via a factory file

This example shows how to define rules in a factory file, that mirrors the rules defined via variables in the previous example. Rules defined via the variable are merged with factory rules and take precedence over them when using the same rule names. The YAML syntax closely follows the `rules` variable type.

```hcl
module "dns-policy" {
  source        = "./fabric/modules/dns-response-policy"
  project_id    = var.project_id
  name          = module.dns-response-policy.name
  policy_create = false
  networks = {
    landing = var.vpc.self_link
  }
  factories_config = {
    rules = "config/rules.yaml"
  }
}
# tftest modules=2 resources=5 files=rules-file fixtures=fixtures/dns-response-policy.tf inventory=complex.yaml e2e
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

### Context

The module supports the contexts interpolation. For example:

```hcl
module "dns-policy" {
  source     = "./fabric/modules/dns-response-policy"
  project_id = "$project_ids:test-project"
  name       = "googleapis"
  networks = {
    landing = "$networks:landing"
  }
  rules = {
    model-armor = {
      dns_name = "$dns_names:rep-model-armor"
      local_data = {
        A = {
          name    = "$dns_names:rep-model-armor"
          rrdatas = ["$addresses:psc-address-rep"]
        }
      }
    }
  }
  context = {
    addresses = {
      psc-address-rep = "10.24.32.25"
    }
    dns_names = {
      rep-model-armor = "modelarmor.europe-west1.rep.googleapis.com."
    }
    networks = {
      landing = "projects/my-project/global/networks/shared-vpc"
    }
    project_ids = {
      test-project = "my-project"
    }
  }
}
# tftest
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L51) | Policy name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L70) | Project id for the zone. | <code>string</code> | ✓ |  |
| [clusters](variables.tf#L17) | Map of GKE clusters to which this policy is applied in name => id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L24) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L36) | Policy description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [factories_config](variables.tf#L42) | Path to folder containing rules data files for the optional factory. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [networks](variables.tf#L56) | Map of VPC self links to which this policy is applied in name => self link format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [policy_create](variables.tf#L63) | Set to false to use the existing policy matching name and only manage rules. | <code>bool</code> |  | <code>true</code> |
| [rules](variables.tf#L75) | Map of policy rules in name => rule format. Local data takes precedence over behavior and is in the form record type => attributes. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified policy id. |  |
| [name](outputs.tf#L22) | Policy name. |  |
| [policy](outputs.tf#L27) | Policy resource. |  |

## Fixtures

- [dns-response-policy.tf](../../tests/fixtures/dns-response-policy.tf)
<!-- END TFDOC -->
