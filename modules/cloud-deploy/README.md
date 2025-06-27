# Cloud Deploy Module

Cloud Deploy Module for creating and managing Delivery Pipelines, Targets, Automations, Deploy Policies and resource-level IAM roles.

<!-- BEGIN TOC -->
- [Limitations](#limitations)
- [Examples](#examples)
- [Single Target Canary Deployment](#single-target-canary-deployment)
- [Single Target Canary Deployment with Custom Traffic Limits](#single-target-canary-deployment-with-custom-traffic-limits)
- [Single Target Canary Deployment with Verification](#single-target-canary-deployment-with-verification)
- [Delivery Pipeline with Existing Target](#delivery-pipeline-with-existing-target)
- [Multiple Targets in Serial Deployment](#multiple-targets-in-serial-deployment)
- [Multi Target Multi Project Deployment](#multi-target-multi-project-deployment)
- [Multi Target with Serial and Parallel deployment](#multi-target-with-serial-and-parallel-deployment)
- [Automation for Delivery Pipelines](#automation-for-delivery-pipelines)
- [Deployment Policy](#deployment-policy)
- [IAM for Delivery Pipeline and Target resource level](#iam-for-delivery-pipeline-and-target-resource-level)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Limitations
> [!WARNING]
> Currently this module only supports Cloud Run deployments and does not include GKE or Custom Target deployments.

## Examples

## Single Target Canary Deployment

This deploys a Cloud Deploy Delivery Pipeline with a single target using the Canary deployment strategy, which by default routes 10% of traffic initially and upon success, shifts to 100% (making it the stable revision). By default `strategy = "STANDARD"` is set, to use canary strategy this needs to be changed to `strategy = "CANARY"`.


```hcl
module "cloud_deploy" {
  source     = "./fabric/modules/cloud-deploy"
  project_id = var.project_id
  region     = var.region
  name       = "deployment-pipeline"

  targets = [
    {
      name        = "dev-target"
      description = "Dev Target"
      profiles    = ["dev"]
      strategy    = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    }
  ]
}
# tftest modules=1 resources=2
```

## Single Target Canary Deployment with Custom Traffic Limits

This deploys a Cloud Deploy Delivery Pipeline with a single target with the Canary deployment strategy. `deployment_percentages` can be set to specify the traffic stages that would be applied during the canary deployment. It accepts integer values in ascending order and between 0 to 99.


```hcl
module "cloud_deploy" {
  source     = "./fabric/modules/cloud-deploy"
  project_id = var.project_id
  region     = var.region
  name       = "deployment-pipeline"


  targets = [
    {
      name                   = "dev-target"
      description            = "Dev Target"
      profiles               = ["dev"]
      strategy               = "CANARY"
      deployment_percentages = [10, 50, 70]
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    }
  ]
}
# tftest modules=1 resources=2
```

## Single Target Canary Deployment with Verification

This deployments enables the rollout to have a verification step by setting `verify = true`. The verification step and configurations need to be passed within the skaffold file.

```hcl
module "cloud_deploy" {
  source     = "./fabric/modules/cloud-deploy"
  project_id = var.project_id
  region     = var.region
  name       = "deployment-pipeline"


  targets = [
    {
      name        = "dev-target"
      description = "Dev Target"
      profiles    = ["dev"]
      strategy    = "CANARY"
      verify      = true
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    }
  ]
}
# tftest modules=1 resources=2
```

## Delivery Pipeline with Existing Target

This deployment demonstrates the ability to create a delivery pipeline by reusing existing targets. By default a `create_target = true` is set, creating and assigning a target to the delivery pipeline. Setting it to false directs the code to assign the target to the delivery pipeline and skip its creation during execution.

```hcl
module "cloud_deploy" {
  source     = "./fabric/modules/cloud-deploy"
  project_id = var.project_id
  region     = var.region
  name       = "deployment-pipeline"


  targets = [
    {
      create_target = false
      name          = "dev-target"
      description   = "Dev Target"
      profiles      = ["dev"]
      strategy      = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    }
  ]
}
# tftest modules=1 resources=1
```

## Multiple Targets in Serial Deployment

Cloud Deployment supports deployments to multiple targets. This example shows how to create 3 targets and to set them in sequence.
The sequence of deployment is defined by the sequence of the target configuration object within the list. `require_approval` can be set to true for any target that requires an approval prior to its deployment/rollout.


```hcl
module "cloud_deploy" {
  source     = "./fabric/modules/cloud-deploy"
  project_id = var.project_id
  region     = var.region
  name       = "deployment-pipeline"


  targets = [
    {
      name        = "dev-target"
      description = "Dev Target"
      profiles    = ["dev"]
      strategy    = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    },
    {
      name        = "qa-target"
      description = "QA Target"
      profiles    = ["qa"]
      strategy    = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    },
    {
      name             = "prod-target"
      description      = "Prod Target"
      profiles         = ["prod"]
      require_approval = true
      strategy         = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    }
  ]
}
# tftest modules=1 resources=4
```


## Multi Target Multi Project Deployment

Targets in this deployment can deploy to different projects. For instance, `qa-target` deploys to a separate `project_id` and `region`. To direct Cloud Run deployments to a different project, specify the `project_id` and `region` under `cloud_run_configs`.  By default, Cloud Run services will use the target's own `project_id` and `region`.


```hcl
module "cloud_deploy" {
  source     = "./fabric/modules/cloud-deploy"
  project_id = var.project_id
  region     = var.region
  name       = "deployment-pipeline"


  targets = [
    {
      name        = "dev-target"
      description = "Dev Target"
      profiles    = ["dev"]
      strategy    = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    },
    {
      name        = "qa-target"
      description = "QA Target"
      profiles    = ["qa"]
      strategy    = "CANARY"
      cloud_run_configs = {
        project_id                = "<cloud_run_project_id>"
        region                    = "<cloud_run_region>"
        automatic_traffic_control = true
      }
    },
    {
      name             = "prod-target"
      description      = "Prod Target"
      profiles         = ["prod"]
      require_approval = true
      strategy         = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    }
  ]
}
# tftest modules=1 resources=4
```

## Multi Target with Serial and Parallel deployment

Cloud Deploy allows deploying to targets in a serial and parallel order. By defining a multi-target target configuration using `multi_target_target_ids` cloud deploy would execute the deployments in parallel. `require_approval` should only be applied to the multi-target target configuration and not the the child targets. As the child targets would execute within the multi-target target configuration, they are excluded from being directly assigned in the serial sequence of the delivery pipeline, using `exclude_from_pipeline = true`.

```hcl
module "cloud_deploy" {
  source     = "./fabric/modules/cloud-deploy"
  project_id = var.project_id
  region     = var.region
  name       = "deployment-pipeline"


  targets = [
    {
      name        = "dev-target"
      description = "Dev Target"
      profiles    = ["dev"]
      strategy    = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    },
    {
      name                    = "multi-qa-target"
      description             = "Multi QA target"
      profiles                = ["multi-qa"]
      multi_target_target_ids = ["qa-target-1", "qa-target-2"]
      strategy                = "STANDARD"
    },
    {
      exclude_from_pipeline = true
      name                  = "qa-target-1"
      description           = "QA target-1"
      profiles              = ["qa-1"]
      strategy              = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    },
    {
      exclude_from_pipeline = true
      name                  = "qa-target-2"
      description           = "QA target-2"
      profiles              = ["qa-2"]
      strategy              = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    }
  ]
}
# tftest modules=1 resources=5
```

## Automation for Delivery Pipelines

This deployment incorporates automations that are supported within a delivery pipeline. If automations are defined at least 1 rule needs to be specified. Rules are defined as `"automation-name" = { <arguments> }` format. Multiple automations can be defined and multiple rules can be specified within an automation. A `service_account` can be provided to execute the automation using the defined service account. If this is missing it defaults to the compute engine default service account (`<project-id>-compute@developer.gserviceaccount.com`).

```hcl
module "cloud_deploy" {
  source     = "./fabric/modules/cloud-deploy"
  project_id = var.project_id
  region     = var.region
  name       = "deployment-pipeline"

  automations = {
    "advance-rollout" = {
      description     = "advance_rollout_rule"
      service_account = "<service_account_name>@<project_id>.iam.gserviceaccount.com"
      advance_rollout_rule = {
        source_phases = ["canary"]
        wait          = "200s"
      }
    },
    "repair-rollout" = {
      description     = "repair_rollout_rule"
      service_account = "<service_account_name>@<project_id>.iam.gserviceaccount.com"
      repair_rollout_rule = {
        jobs   = ["predeploy", "deploy", "postdeploy", "verify"]
        phases = ["canary-10", "stable"]
        rollback = {
          destination_phase = "stable"
        }
      }
    }
  }

  targets = [
    {
      name        = "dev-target"
      description = "Dev Target"
      profiles    = ["dev"]
      strategy    = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    }
  ]
}
# tftest modules=1 resources=4
```

## Deployment Policy

This example provides a way to define a deployment policy along with the delivery pipeline. Each deploy policy can be defined as `"deploy_policy_name" = { <arguments> }` format. Rollout restrictions are defined as `"restriction_name" = { <arguments> }` format.
By default, the deployment policy defined below applies to all delivery pipelines. If this requires a change, modify the selector option. Selector types supported are: "DELIVERY_PIPELINE" and "TARGET".

```hcl
module "cloud_deploy" {
  source     = "./fabric/modules/cloud-deploy"
  project_id = var.project_id
  region     = var.region
  name       = "deployment-pipeline"

  targets = [
    {
      name        = "dev-target"
      description = "Dev Target"
      profiles    = ["dev"]
      strategy    = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
    }
  ]

  deploy_policies = {
    "deploy-policy" = {
      selectors = [{
        id   = "*"
        type = "DELIVERY_PIPELINE"
      }]
      rollout_restrictions = {
        "restriction-1" = {
          time_zone = "Australia/Melbourne"
          weekly_windows = [{
            days_of_week = ["MONDAY", "TUESDAY"]

            start_time = {
              hours   = "10"
              minutes = "30"
              seconds = "00"
              nanos   = "00"
            }

            end_time = {
              hours   = "12"
              minutes = "30"
              seconds = "00"
              nanos   = "00"
            }
          }]
      } }
    }
  }
}
# tftest modules=1 resources=3
```

## IAM for Delivery Pipeline and Target resource level

This example specifies the option to set IAM roles at the Delivery Pipeline and Target resource level. IAM bindings support the usual syntax.
`iam`, `iam_bindings`, `iam_bindings_additive`, `iam_by_principals` are supported for delivery pipelines and targets.

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-deploy"
  project_id = var.project_id
  region     = var.region
  name       = "deployment-pipeline"

  iam = { "roles/clouddeploy.developer" = ["user:allUsers"] }

  targets = [
    {
      name        = "dev-target"
      description = "Dev Target"
      profiles    = ["dev"]
      strategy    = "CANARY"
      cloud_run_configs = {
        automatic_traffic_control = true
      }
      iam = { "roles/clouddeploy.operator" = ["user:allUsers"] }
    }
  ]
}
# tftest modules=1 resources=4
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L191) | Cloud Deploy Delivery Pipeline name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L201) | Project id used for resources, if not explicitly specified. | <code>string</code> | ✓ |  |
| [region](variables.tf#L206) | Region used for resources, if not explicitly specified. | <code>string</code> | ✓ |  |
| [annotations](variables.tf#L17) | Resource annotations. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [automations](variables.tf#L24) | Configuration for automations associated with the deployment pipeline in a name => attributes format. | <code title="map&#40;object&#40;&#123;&#10;  project_id      &#61; optional&#40;string, null&#41;&#10;  region          &#61; optional&#40;string, null&#41;&#10;  annotations     &#61; optional&#40;map&#40;string&#41;&#41;&#10;  description     &#61; optional&#40;string, null&#41;&#10;  labels          &#61; optional&#40;map&#40;string&#41;&#41;&#10;  service_account &#61; optional&#40;string, null&#41;&#10;  suspended       &#61; optional&#40;bool, false&#41;&#10;  advance_rollout_rule &#61; optional&#40;object&#40;&#123;&#10;    id            &#61; optional&#40;string, &#34;advance-rollout&#34;&#41;&#10;    source_phases &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    wait          &#61; optional&#40;string, null&#41;&#10;  &#125;&#41;&#41;&#10;  promote_release_rule &#61; optional&#40;object&#40;&#123;&#10;    id                    &#61; optional&#40;string, &#34;promote-release&#34;&#41;&#10;    wait                  &#61; optional&#40;string, null&#41;&#10;    destination_target_id &#61; optional&#40;string, null&#41;&#10;    destination_phase     &#61; optional&#40;string, null&#41;&#10;  &#125;&#41;&#41;&#10;  repair_rollout_rule &#61; optional&#40;object&#40;&#123;&#10;    id     &#61; optional&#40;string, &#34;repair-rollout&#34;&#41;&#10;    phases &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    jobs   &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    retry &#61; optional&#40;object&#40;&#123;&#10;      attempts     &#61; optional&#40;string, null&#41;&#10;      wait         &#61; optional&#40;string, null&#41;&#10;      backoff_mode &#61; optional&#40;string, null&#41;&#10;    &#125;&#41;&#41;&#10;    rollback &#61; optional&#40;object&#40;&#123;&#10;      destination_phase                   &#61; optional&#40;string, null&#41;&#10;      disable_rollback_if_rollout_pending &#61; optional&#40;bool, true&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  timed_promote_release_rule &#61; optional&#40;object&#40;&#123;&#10;    id                    &#61; optional&#40;string, &#34;timed-promote-release&#34;&#41;&#10;    destination_target_id &#61; optional&#40;string, null&#41;&#10;    schedule              &#61; optional&#40;string, null&#41;&#10;    time_zone             &#61; optional&#40;string, null&#41;&#10;    destination_phase     &#61; optional&#40;string, null&#41;&#10;  &#125;&#41;&#41;&#10;  selector &#61; optional&#40;list&#40;object&#40;&#123;&#10;    id     &#61; optional&#40;string, &#34;&#42;&#34;&#41;&#10;    labels &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#91;&#123; id &#61; &#34;&#42;&#34; &#125;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [deploy_policies](variables.tf#L84) | Configurations for Deployment Policies in a name => attributes format. | <code title="map&#40;object&#40;&#123;&#10;  project_id  &#61; optional&#40;string, null&#41;&#10;  region      &#61; optional&#40;string, null&#41;&#10;  annotations &#61; optional&#40;map&#40;string&#41;&#41;&#10;  description &#61; optional&#40;string, null&#41;&#10;  labels      &#61; optional&#40;map&#40;string&#41;&#41;&#10;  suspended   &#61; optional&#40;bool, false&#41;&#10;  rollout_restrictions &#61; map&#40;object&#40;&#123;&#10;    actions   &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    invokers  &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    time_zone &#61; optional&#40;string&#41;&#10;    weekly_windows &#61; optional&#40;list&#40;object&#40;&#123;&#10;      days_of_week &#61; optional&#40;list&#40;string&#41;&#41;&#10;      start_time &#61; optional&#40;object&#40;&#123;&#10;        hours   &#61; optional&#40;string&#41;&#10;        minutes &#61; optional&#40;string&#41;&#10;        seconds &#61; optional&#40;string&#41;&#10;        nanos   &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      end_time &#61; optional&#40;object&#40;&#123;&#10;        hours   &#61; optional&#40;string&#41;&#10;        minutes &#61; optional&#40;string&#41;&#10;        seconds &#61; optional&#40;string&#41;&#10;        nanos   &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    one_time_windows &#61; optional&#40;list&#40;object&#40;&#123;&#10;      start_date &#61; optional&#40;object&#40;&#123;&#10;        day   &#61; optional&#40;string&#41;&#10;        month &#61; optional&#40;string&#41;&#10;        year  &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      start_time &#61; optional&#40;object&#40;&#123;&#10;        hours   &#61; optional&#40;string&#41;&#10;        minutes &#61; optional&#40;string&#41;&#10;        seconds &#61; optional&#40;string&#41;&#10;        nanos   &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      end_date &#61; optional&#40;object&#40;&#123;&#10;        day   &#61; optional&#40;string&#41;&#10;        month &#61; optional&#40;string&#41;&#10;        year  &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      end_time &#61; optional&#40;object&#40;&#123;&#10;        hours   &#61; optional&#40;string&#41;&#10;        minutes &#61; optional&#40;string&#41;&#10;        seconds &#61; optional&#40;string&#41;&#10;        nanos   &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;  selectors &#61; optional&#40;list&#40;object&#40;&#123;&#10;    id     &#61; optional&#40;string, &#34;&#42;&#34;&#41;&#10;    type   &#61; optional&#40;string, &#34;DELIVERY_PIPELINE&#34;&#41;&#10;    labels &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#91;&#123; id &#61; &#34;&#42;&#34;, type &#61; &#34;DELIVERY_PIPELINE&#34; &#125;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L165) | Cloud Deploy Delivery Pipeline description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [iam](variables-iam.tf#L17) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L39) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L54) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L176) | Cloud Deploy Delivery Pipeline resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [suspended](variables.tf#L211) | Configuration to suspend a delivery pipeline. | <code>bool</code> |  | <code>false</code> |
| [targets](variables.tf#L218) | Configuration for new targets associated with the delivery pipeline in a list format. Order of the targets are defined by the order within the list. | <code title="list&#40;object&#40;&#123;&#10;  project_id                &#61; optional&#40;string, null&#41;&#10;  region                    &#61; optional&#40;string, null&#41;&#10;  name                      &#61; string&#10;  create_target             &#61; optional&#40;bool, true&#41;&#10;  exclude_from_pipeline     &#61; optional&#40;bool, false&#41;&#10;  annotations               &#61; optional&#40;map&#40;string&#41;&#41;&#10;  description               &#61; optional&#40;string, null&#41;&#10;  deployment_percentages    &#61; optional&#40;list&#40;number&#41;, &#91;10&#93;&#41;&#10;  execution_configs_usages  &#61; optional&#40;list&#40;string&#41;&#41;&#10;  execution_configs_timeout &#61; optional&#40;string, null&#41;&#10;  labels                    &#61; optional&#40;map&#40;string&#41;&#41;&#10;  multi_target_target_ids   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  profiles                  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  predeploy_actions         &#61; optional&#40;list&#40;string&#41;&#41;&#10;  postdeploy_actions        &#61; optional&#40;list&#40;string&#41;&#41;&#10;  require_approval          &#61; optional&#40;bool, false&#41;&#10;  strategy                  &#61; optional&#40;string, &#34;STANDARD&#34;&#41;&#10;  target_deploy_parameters  &#61; optional&#40;map&#40;string&#41;, null&#41;&#10;  verify                    &#61; optional&#40;bool, false&#41;&#10;  cloud_run_configs &#61; optional&#40;object&#40;&#123;&#10;    project_id                &#61; optional&#40;string, null&#41;&#10;    region                    &#61; optional&#40;string, null&#41;&#10;    automatic_traffic_control &#61; optional&#40;bool, true&#41;&#10;    canary_revision_tags      &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    prior_revision_tags       &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    stable_revision_tags      &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;  &#125;&#41;&#41;&#10;  custom_canary_phase_configs &#61; optional&#40;map&#40;object&#40;&#123;&#10;    deployment_percentage &#61; string&#10;    predeploy_actions     &#61; optional&#40;list&#40;string&#41;&#41;&#10;    postdeploy_actions    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  delivery_pipeline_deploy_parameters &#61; optional&#40;list&#40;object&#40;&#123;&#10;    values                 &#61; optional&#40;map&#40;string&#41;, null&#41;&#10;    matching_target_labels &#61; optional&#40;map&#40;string&#41;, null&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_by_principals &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [automation_ids](outputs.tf#L18) | Automation ids. |  |
| [deploy_policy_ids](outputs.tf#L23) | Deploy Policy ids. |  |
| [pipeline_id](outputs.tf#L28) | Delivery pipeline id. |  |
| [target_ids](outputs.tf#L33) | Target ids. |  |
<!-- END TFDOC -->
