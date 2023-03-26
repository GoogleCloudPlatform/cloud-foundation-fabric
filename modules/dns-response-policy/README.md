# Google Cloud DNS Response Policy

This module allows management of a [Google Cloud DNS policy and its rules](https://cloud.google.com/dns/docs/zones/manage-response-policies). The policy can be already existing and passed in via its id.

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
# tftest modules=1 resources=2
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
    default = {
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
          rrdatas = ["199.36.153.4", "199.36.153.5"]
        }
      }
    }
  }
}
# tftest modules=1 resources=3
```

<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L36) | Zone name, must be unique within the project. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L48) | Project id for the zone. | <code>string</code> | ✓ |  |
| [clusters](variables.tf#L17) | List of GKE cluster ids to which this policy is applied. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [description](variables.tf#L24) | Policy description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [id](variables.tf#L30) | Use the existing policy matching id and only manage rules. | <code>string</code> |  | <code>null</code> |
| [networks](variables.tf#L41) | List of VPC self links to which this policy is applied. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [rules](variables.tf#L53) | Map of policy rules in name => rule format. Local data takes precedence over behavior. | <code title="map&#40;object&#40;&#123;&#10;  dns_name &#61; string&#10;  behavior &#61; optional&#40;string, &#34;bypassResponsePolicy&#34;&#41;&#10;  local_data &#61; optional&#40;map&#40;object&#40;&#123;&#10;    ttl &#61; optional&#40;number&#41;&#10;    rrdatas &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Policy id. |  |

<!-- END TFDOC -->
