# Billing Account Module

This module allows managing resources and policies related to a billing account:

- IAM bindings
- log sinks
- billing budgets and their notifications

Managing billing-related resources via application default credentials [requires a billing project to be set](https://cloud.google.com/docs/authentication/troubleshoot-adc#user-creds-client-based). To configure one via Terraform you can use a snippet similar to this one:

```hcl
provider "google" {
  billing_project       = "my-project"
  user_project_override = true
}
# tftest skip
```

<!-- BEGIN TOC -->
- [Examples](#examples)
- [IAM](#iam)
  - [Log sinks](#log-sinks)
  - [Billing budgets](#billing-budgets)
    - [PubSub update rules](#pubsub-update-rules)
    - [Monitoring channels](#monitoring-channels)
    - [Budget factory](#budget-factory)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

## IAM

IAM is managed via several variables that implement different features and levels of control:

- `iam` and `iam_by_principals` configure authoritative bindings that manage individual roles exclusively, and are internally merged
- `iam_bindings` configure authoritative bindings with optional support for conditions, and are not internally merged with the previous two variables
- `iam_bindings_additive` configure additive bindings via individual role/member pairs with optional support  conditions

The authoritative and additive approaches can be used together, provided different roles are managed by each. Some care must also be taken with the `iam_by_principals` variable to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

Refer to the [project module](../project/README.md#iam) for examples of the IAM interface. IAM also supports variable interpolation for both roles and principals and for the foreign resources where the service account is the principal, via the respective attributes in the `var.context` variable. Basic usage is shown in the example below.

```hcl
module "billing-account" {
  source = "./fabric/modules/billing-account"
  id     = "012345-ABCDEF-012345"
  context = {
    iam_principals = {
      org-admins = "group:gcp-organization-admins@example.com"
    }
  }
  iam = {
    "roles/billing.admin" = [
      "$iam_principals:org-admins",
      "serviceAccount:foo@myprj.iam.gserviceaccount.com"
    ]
  }
  iam_bindings = {
    conditional-admin = {
      members = [
        "serviceAccount:pf-dev@myprj.iam.gserviceaccount.com"
      ]
      role = "roles/billing.admin"
      condition = {
        title = "pf-dev-conditional-billing-admin"
        expression = (
          "resource.matchTag('123456/environment', 'development')"
        )
      }
    }
  }
  iam_bindings_additive = {
    sa-net-iac-user = {
      member = "serviceAccount:net-iac-0@myprj.iam.gserviceaccount.com"
      role   = "roles/billing.user"
    }
  }
  iam_by_principals = {
    "group:billing-admins@example.org" = ["roles/billing.admin"]
  }
}
# tftest modules=1 resources=3 inventory=iam.yaml
```

### Log sinks

Billing account log sinks use the same format used for log sinks in the resource manager modules (organization, folder, project).

```hcl
module "log-bucket-all" {
  source = "./fabric/modules/logging-bucket"
  parent = "myprj"
  name   = "billing-account-all"
}

module "billing-account" {
  source = "./fabric/modules/billing-account"
  id     = "012345-ABCDEF-012345"
  logging_sinks = {
    all = {
      destination = module.log-bucket-all.id
      type        = "logging"
    }
  }
}
# tftest modules=2 resources=3 inventory=logging.yaml
```

### Billing budgets

Billing budgets expose all the attributes of the underlying resource, and allow using external notification channels, or creating them via this same module.

```hcl
module "billing-account" {
  source = "./fabric/modules/billing-account"
  id     = "012345-ABCDEF-012345"
  budgets = {
    folder-net-month-current-100 = {
      display_name = "100 dollars in current spend"
      amount = {
        units = 100
      }
      filter = {
        period = {
          calendar = "MONTH"
        }
        resource_ancestors = ["folders/1234567890"]
      }
      threshold_rules = [
        { percent = 0.5 },
        { percent = 0.75 }
      ]
    }
  }
}
# tftest modules=1 resources=1 inventory=budget-simple.yaml
```

#### PubSub update rules

Update rules can notify pubsub topics.

```hcl
module "pubsub-billing-topic" {
  source     = "./fabric/modules/pubsub"
  project_id = "my-prj"
  name       = "budget-default"
}

module "billing-account" {
  source = "./fabric/modules/billing-account"
  id     = "012345-ABCDEF-012345"
  budgets = {
    folder-net-month-current-100 = {
      display_name = "100 dollars in current spend"
      amount = {
        units = 100
      }
      filter = {
        period = {
          calendar = "MONTH"
        }
        resource_ancestors = ["folders/1234567890"]
      }
      threshold_rules = [
        { percent = 0.5 },
        { percent = 0.75 }
      ]
      update_rules = {
        default = {
          pubsub_topic = module.pubsub-billing-topic.id
        }
      }
    }
  }
}
# tftest modules=2 resources=2 inventory=budget-pubsub.yaml
```

#### Monitoring channels

Monitoring channels can be referenced in update rules either by passing in an existing channel id, or by using a reference to a key in the `budget_notification_channels` variable, that allows managing ad hoc monitoring channels.

<!-- markdownlint-disable MD034 -->

```hcl
module "billing-account" {
  source = "./fabric/modules/billing-account"
  id     = "012345-ABCDEF-012345"
  budget_notification_channels = {
    billing-default = {
      project_id = "tf-playground-simple"
      type       = "email"
      labels = {
        email_address = "gcp-billing-admins@example.com"
      }
    }
  }
  budgets = {
    folder-net-month-current-100 = {
      display_name = "100 dollars in current spend"
      amount = {
        units = 100
      }
      filter = {
        period = {
          calendar = "MONTH"
        }
        resource_ancestors = ["folders/1234567890"]
      }
      threshold_rules = [
        { percent = 0.5 },
        { percent = 0.75 }
      ]
      update_rules = {
        default = {
          disable_default_iam_recipients   = true
          monitoring_notification_channels = ["billing-default"]
        }
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=budget-monitoring-channel.yaml
```

#### Budget factory

This module also exposes a factory for billing budgets, that works in a similar way to factories in other modules: a specific folder is searched for YAML files, which contain one budget description per file. The file name is used to generate the key of the resulting map of budgets, which is merged with the one coming from the `budgets` variable. The YAML files support the same type of the `budgets` variable.

```hcl
module "billing-account" {
  source = "./fabric/modules/billing-account"
  id     = "012345-ABCDEF-012345"
  budget_notification_channels = {
    billing-default = {
      project_id = "tf-playground-simple"
      type       = "email"
      labels = {
        email_address = "gcp-billing-admins@example.com"
      }
    }
  }
  factories_config = {
    budgets_data_path = "data/billing-budgets"
  }
}
# tftest modules=1 resources=2 files=test-1  inventory=budget-factory.yaml
```

```yaml
display_name: 100 dollars in current spend
amount:
  units: 100
filter:
  period:
    custom:
      start_date:
        day: 1
        month: 1
        year: 2026
  resource_ancestors:
  - folders/1234567890
threshold_rules:
- percent: 0.5
- percent: 0.75
update_rules:
  default:
    disable_default_iam_recipients: true
    monitoring_notification_channels:
    - billing-default

# tftest-file id=test-1 path=data/billing-budgets/folder-net-month-current-100.yaml schema=budget.schema.json
```

<!-- markdownlint-enable -->
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [id](variables.tf#L165) | Billing account id. | <code>string</code> | ✓ |  |
| [budget_notification_channels](variables.tf#L17) | Notification channels used by budget alerts. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [budgets](variables.tf#L47) | Billing budgets. Notification channels are either keys in corresponding variable, or external ids. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L139) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [factories_config](variables.tf#L156) | Path to folder containing budget alerts data files. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables-iam.tf#L17) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L39) | Individual additive IAM bindings. Keys are arbitrary. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L54) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_sinks](variables.tf#L170) | Logging sinks to create for the billing account. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [projects](variables.tf#L203) | Projects associated with this billing account. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [billing_budget_ids](outputs.tf#L17) | Billing budget ids. |  |
| [monitoring_notification_channel_ids](outputs.tf#L25) | Monitoring notification channel ids. |  |
<!-- END TFDOC -->
