# Google Cloud Organization Policy

This module allows creation and management of [GCP Organization Policies](https://cloud.google.com/resource-manager/docs/organization-policy/org-policy-constraints) by defining them in a well formatted `yaml` files or with HCL.

Yaml based factory can simplify centralized management of Org Policies for a DevSecOps team by providing a simple way to define/structure policies and exclusions.

## Example

### Terraform code

```hcl
# using configuration provided in a set of yaml files
module "org-policy-factory" {
  source = "./modules/organization-policy"

  config_directory = "./policies"
}

# using configuration provided in the module variable
module "org-policy" {
  source = "./modules/organization-policy"
  
  organization_policies = {
    "folders/1234567890" = {
        "constraints/iam.disableServiceAccountKeyUpload" = {
          rules = [
            {
                enforce = true
            }
          ]
        }
    },
    "organizations/1234567890" = {
      "run.allowedIngress" = {
        rules = [
          {
            condition = {
              description= "allow ingress"
              expression = "resource.matchTag('123456789/environment', 'prod')"
              title = "allow-for-prod-org"
            },
            values = {
              allowed_values = ["internal"]
            }
          }
        ]
      }
    }
  } 
}
# tftest skip
```

## Org Policy definition format and structure

### Structure of `organization_policies` variable

```hcl
organization_policies = {
  "parent_id" = { # parent id in format projects/project-id, folders/1234567890 or organizations/1234567890.
    "policy_name" = { # policy constraint id, for example compute.vmExternalIpAccess.
      inherit_from_parent = true|false # (Optional) Only for list constraints. Determines the inheritance behavior for this policy.
      reset               = true|false # (Optional) Ignores policies set above this resource and restores the constraint_default enforcement behavior.
      rules               = [ # Up to 10 PolicyRules are allowed.
        {
          allow_all = true|false # (Optional) Only for list constraints. Setting this to true means that all values are allowed.
          deny_all  = true|false # (Optional) Only for list constraints. Setting this to true means that all values are denied.
          enforce   = true|false # (Optional) Only for boolean constraints. If true, then the Policy is enforced.
          condition = {          # (Optional) A condition which determines whether this rule is used in the evaluation of the policy.
            description = "Condition description" # (Optional)
            expression  = "Condition expression"  # (Optional) For example "resource.matchTag('123456789/environment', 'prod')".
            location    = "policy-error.log"      # (Optional) String indicating the location of the expression for error reporting.
            title       = "condition-title"       # (Optional)
          }
          values = {             # (Optional) Only for list constraints. List of values to be used for this PolicyRule.
            allowed_values = ["value1", "value2"] # (Optional) List of values allowed at this resource.
            denied_values  = ["value3", "value4"] # (Optional) List of values denied at this resource.
          }
        }
      ]
    }
  }
}
# tftest skip
```

### Structure of configuration provided in a yaml file/s

Configuration should be placed in a set of yaml files in the config directory. Policy entry structure as follows:

```yaml
parent_id: # parent id in format projects/project-id, folders/1234567890 or organizations/1234567890.
  policy_name1: # policy constraint id, for example compute.vmExternalIpAccess.
    inherit_from_parent: true|false # (Optional) Only for list constraints. Determines the inheritance behavior for this policy.
    reset: true|false               # (Optional) Ignores policies set above this resource and restores the constraint_default enforcement behavior.
    rules:
      - allow_all: true|false # (Optional) Only for list constraints. Setting this to true means that all values are allowed.
        deny_all: true|false  # (Optional) Only for list constraints. Setting this to true means that all values are denied.
        enforce: true|false   # (Optional) Only for boolean constraints. If true, then the Policy is enforced.
        condition:            # (Optional) A condition which determines whether this rule is used in the evaluation of the policy.
          description: Condition description   # (Optional)
          expression: Condition expression     # (Optional) For example resource.matchTag("123456789/environment", "prod")
          location: policy-error.log           # (Optional) String indicating the location of the expression for error reporting.
          title: condition-title               # (Optional)
        values:               # (Optional) Only for list constraints. List of values to be used for this PolicyRule.
          allowed_values: ['value1', 'value2'] # (Optional) List of values allowed at this resource.
          denied_values:  ['value3', 'value4'] # (Optional) List of values denied at this resource.

```

Module allows policies to be distributed into multiple yaml files for a better management and navigation.

```bash
├── org-policies
│   ├── baseline.yaml
│   ├── image-import-projects.yaml
│   └── exclusions.yaml
```

Organization policies example yaml configuration

```bash
cat ./policies/baseline.yaml
organizations/1234567890:
  constraints/compute.vmExternalIpAccess:
    rules:
      - deny_all: true
folders/1234567890:
  compute.vmCanIpForward:
    inherit_from_parent: false
    reset: false
    rules:
      - allow_all: true
projects/my-project-id:
  run.allowedIngress:
    inherit_from_parent: true
    rules:
      - condition:
          description: allow internal ingress
          expression: resource.matchTag("123456789/environment", "prod")
          location: test.log
          title: allow-for-prod
        values: 
          allowed_values: ['internal']
  iam.allowServiceAccountCredentialLifetimeExtension:
    rules:
      - allow_all: true
  compute.disableGlobalLoadBalancing:
    reset: true
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [config_directory](variables.tf#L17) | Paths to a folder where organization policy configs are stored in yaml format. Files suffix must be `.yaml`. | <code>string</code> |  | <code>null</code> |
| [organization_policies](variables.tf#L25) | Organization policies keyed by parent in format `projects/project-id`, `folders/1234567890` or `organizations/1234567890`. | <code>any</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [organization_policies](outputs.tf#L17) | Organization policies. |  |

<!-- END TFDOC -->
