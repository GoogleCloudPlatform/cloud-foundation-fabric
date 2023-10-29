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
  - [IAM bindings](#iam-bindings)
  - [Log sinks](#log-sinks)
  - [Billing budgets](#billing-budgets)
    - [PubSub update rules](#pubsub-update-rules)
    - [Monitoring channels](#monitoring-channels)
    - [Budget factory](#budget-factory)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

### IAM bindings

Billing account IAM bindings implement [the same interface](../__docs/20230816-iam-refactor.md) used for all other modules.

```hcl
module "billing-account" {
  source = "./fabric/modules/billing-account"
  id     = "012345-ABCDEF-012345"
  group_iam = {
    "billing-admins@example.org" = ["roles/billing.admin"]
  }
  iam = {
    "roles/billing.admin" = [
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
}
# tftest modules=1 resources=3 inventory=iam.yaml
```

### Log sinks

Billing account log sinks use the same format used for log sinks in the resource manager modules (organization, folder, project).

```hcl
module "log-bucket-all" {
  source      = "./fabric/modules/logging-bucket"
  parent_type = "project"
  parent      = "myprj"
  id          = "billing-account-all"
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
}
# tftest modules=1 resources=2 files=test-1  inventory=budget-monitoring-channel.yaml
```

```yaml
# tftest-file id=test-1 path=data/billing-budgets/folder-net-month-current-100.yaml
display_name: 100 dollars in current spend
amount:
  units: 100
filter:
  period:
    calendar: MONTH
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
```

<!-- markdownlint-enable -->
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [id](variables.tf#L175) | Billing account id. | <code>string</code> | ✓ |  |
| [budget_notification_channels](variables.tf#L17) | Notification channels used by budget alerts. | <code title="map&#40;object&#40;&#123;&#10;  project_id   &#61; string&#10;  type         &#61; string&#10;  description  &#61; optional&#40;string&#41;&#10;  display_name &#61; optional&#40;string&#41;&#10;  enabled      &#61; optional&#40;bool, true&#41;&#10;  force_delete &#61; optional&#40;bool&#41;&#10;  labels       &#61; optional&#40;map&#40;string&#41;&#41;&#10;  sensitive_labels &#61; optional&#40;list&#40;object&#40;&#123;&#10;    auth_token  &#61; optional&#40;string&#41;&#10;    password    &#61; optional&#40;string&#41;&#10;    service_key &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  user_labels &#61; optional&#40;map&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [budgets](variables.tf#L47) | Billing budgets. Notification channels are either keys in corresponding variable, or external ids. | <code title="map&#40;object&#40;&#123;&#10;  amount &#61; object&#40;&#123;&#10;    currency_code   &#61; optional&#40;string&#41;&#10;    nanos           &#61; optional&#40;number&#41;&#10;    units           &#61; optional&#40;number&#41;&#10;    use_last_period &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#10;  display_name &#61; optional&#40;string&#41;&#10;  filter &#61; optional&#40;object&#40;&#123;&#10;    credit_types_treatment &#61; optional&#40;object&#40;&#123;&#10;      exclude_all       &#61; optional&#40;bool&#41;&#10;      include_specified &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    label &#61; optional&#40;object&#40;&#123;&#10;      key   &#61; string&#10;      value &#61; string&#10;    &#125;&#41;&#41;&#10;    period &#61; optional&#40;object&#40;&#123;&#10;      calendar &#61; optional&#40;string&#41;&#10;      custom &#61; optional&#40;object&#40;&#123;&#10;        start_date &#61; object&#40;&#123;&#10;          day   &#61; number&#10;          month &#61; number&#10;          year  &#61; number&#10;        &#125;&#41;&#10;        end_date &#61; optional&#40;object&#40;&#123;&#10;          day   &#61; number&#10;          month &#61; number&#10;          year  &#61; number&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    projects           &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resource_ancestors &#61; optional&#40;list&#40;string&#41;&#41;&#10;    services           &#61; optional&#40;list&#40;string&#41;&#41;&#10;    subaccounts        &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  threshold_rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;    percent          &#61; number&#10;    forecasted_spend &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  update_rules &#61; optional&#40;map&#40;object&#40;&#123;&#10;    disable_default_iam_recipients   &#61; optional&#40;bool&#41;&#10;    monitoring_notification_channels &#61; optional&#40;list&#40;string&#41;&#41;&#10;    pubsub_topic                     &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [factory_config](variables.tf#L121) | Path to folder containing budget alerts data files. | <code title="object&#40;&#123;&#10;  budgets_data_path &#61; optional&#40;string, &#34;data&#47;billing-budgets&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [group_iam](variables.tf#L131) | Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L138) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L145) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L160) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_sinks](variables.tf#L180) | Logging sinks to create for the organization. | <code title="map&#40;object&#40;&#123;&#10;  destination          &#61; string&#10;  type                 &#61; string&#10;  bq_partitioned_table &#61; optional&#40;bool&#41;&#10;  description          &#61; optional&#40;string&#41;&#10;  disabled             &#61; optional&#40;bool, false&#41;&#10;  exclusions &#61; optional&#40;map&#40;object&#40;&#123;&#10;    filter      &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;    disabled    &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  filter &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [projects](variables.tf#L213) | Projects associated with this billing account. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [billing_budget_ids](outputs.tf#L17) | Billing budget ids. |  |
| [monitoring_notification_channel_ids](outputs.tf#L25) | Monitoring notification channel ids. |  |
<!-- END TFDOC -->
