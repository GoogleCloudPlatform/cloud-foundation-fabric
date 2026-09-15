# Google Cloud Workflows Module

This module manages Google Cloud Workflows, providing end-to-end support for serverless workflow orchestration, execution call logging, user environment variables, revisions, dedicated Service Account creation, invoker IAM bindings, Cloud Tasks queues, Cloud Scheduler jobs, and Eventarc triggers.

<!-- BEGIN TOC -->
- [Basic Workflow](#basic-workflow)
- [Workflow with Dedicated Service Account and Call Logging](#workflow-with-dedicated-service-account-and-call-logging)
- [Workflow with Scheduled Execution (Cloud Scheduler) and Invoker IAM](#workflow-with-scheduled-execution-cloud-scheduler-and-invoker-iam)
- [Workflow with Cloud Tasks Queue](#workflow-with-cloud-tasks-queue)
- [Event-Driven Workflow with Eventarc Trigger](#event-driven-workflow-with-eventarc-trigger)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Basic Workflow

```hcl
module "workflow" {
  source      = "./fabric/modules/workflows"
  project_id  = var.project_id
  prefix      = "dev"
  name        = "my-workflow"
  region      = "us-central1"
  description = "Basic sample workflow."
  labels = {
    env = "dev"
  }
  source_contents = <<-EOT
    main:
      params: [args]
      steps:
        - step1:
            return: "Hello from Cloud Workflows!"
  EOT
}
# tftest modules=1 resources=1
```

## Workflow with Dedicated Service Account and Call Logging

```hcl
module "workflow_with_sa" {
  source                  = "./fabric/modules/workflows"
  project_id              = var.project_id
  name                    = "logged-workflow"
  region                  = "europe-west1"
  call_log_level          = "LOG_ALL_CALLS"
  execution_history_level = "EXECUTION_HISTORY_DETAILED"
  deletion_protection     = false
  service_account_create  = true
  service_account_roles   = ["roles/logging.logWriter"]
  user_env_vars = {
    ENVIRONMENT = "production"
  }
  source_contents = <<-EOT
    main:
      params: [args]
      steps:
        - step1:
            return: $${sys.get_env("ENVIRONMENT")}
  EOT
}
# tftest modules=1 resources=3
```

## Workflow with Scheduled Execution (Cloud Scheduler) and Invoker IAM

```hcl
module "workflow_scheduled" {
  source          = "./fabric/modules/workflows"
  project_id      = var.project_id
  name            = "scheduled-workflow"
  region          = "europe-west1"
  service_account = "custom-sa@${var.project_id}.iam.gserviceaccount.com"
  iam = {
    "roles/workflows.invoker" = [
      "serviceAccount:scheduler-sa@${var.project_id}.iam.gserviceaccount.com"
    ]
  }
  scheduler_jobs = {
    daily-sync = {
      schedule  = "0 4 * * *"
      time_zone = "Etc/UTC"
      argument  = jsonencode({ sync_mode = "incremental" })
      retry_config = {
        retry_count = 3
      }
    }
  }
  source_contents = <<-EOT
    main:
      params: [args]
      steps:
        - step1:
            return: $${args.sync_mode}
  EOT
}
# tftest modules=1 resources=3
```

## Workflow with Cloud Tasks Queue

```hcl
module "workflow_with_queue" {
  source          = "./fabric/modules/workflows"
  project_id      = var.project_id
  name            = "tasks-workflow"
  region          = "us-central1"
  crypto_key_name = "projects/${var.project_id}/locations/us-central1/keyRings/my-ring/cryptoKeys/my-key"
  task_queues = {
    workflow-tasks = {
      rate_limits = {
        max_dispatches_per_second = 10
        max_concurrent_dispatches = 5
      }
      retry_config = {
        max_attempts = 5
        min_backoff  = "1s"
        max_backoff  = "10s"
      }
    }
  }
  source_contents = <<-EOT
    main:
      params: [args]
      steps:
        - step1:
            return: "Processed"
  EOT
}
# tftest modules=1 resources=2
```

## Event-Driven Workflow with Eventarc Trigger

```hcl
module "workflow_eventarc" {
  source                 = "./fabric/modules/workflows"
  project_id             = var.project_id
  name                   = "eventarc-workflow"
  region                 = "europe-west1"
  service_account_create = true
  eventarc_triggers = {
    pubsub-trigger = {
      matching_criteria = [
        {
          attribute = "type"
          value     = "google.cloud.pubsub.topic.v1.messagePublished"
        }
      ]
      pubsub_topic = "projects/${var.project_id}/topics/my-topic"
      retry_policy = {
        max_attempts = 3
      }
    }
  }
  source_contents = <<-EOT
    main:
      params: [event]
      steps:
        - log_event:
            return: $${event}
  EOT
}
# tftest modules=1 resources=3
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L120) | Name of the Workflow. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L135) | The ID of the project in which the resource belongs. | <code>string</code> | ✓ |  |
| [call_log_level](variables.tf#L15) | Describes the level of platform logging to apply to calls and call responses during executions of this workflow. | <code>string</code> |  | <code>&#34;LOG_ALL_CALLS&#34;</code> |
| [context](variables.tf#L28) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [crypto_key_name](variables.tf#L41) | The KMS key name used to encrypt workflow data at rest. | <code>string</code> |  | <code>null</code> |
| [deletion_protection](variables.tf#L47) | Whether deletion protection is enabled for this workflow. | <code>bool</code> |  | <code>false</code> |
| [description](variables.tf#L53) | Description of the workflow. | <code>string</code> |  | <code>&#34;Managed by Terraform.&#34;</code> |
| [eventarc_triggers](variables.tf#L59) | Eventarc triggers that invoke this workflow. Map keys are trigger names. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [execution_history_level](variables.tf#L80) | Describes the level of execution history to apply to executions of this workflow. | <code>string</code> |  | <code>null</code> |
| [iam](variables.tf#L100) | IAM bindings for this workflow in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables.tf#L107) | Authoritative IAM binding for this workflow in {PRINCIPAL => [ROLES]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L114) | A set of key/value label pairs to assign to this Workflow. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L125) | Optional prefix used for resource names. | <code>string</code> |  | <code>null</code> |
| [region](variables.tf#L140) | The region of the workflow. | <code>string</code> |  | <code>&#34;us-central1&#34;</code> |
| [scheduler_jobs](variables.tf#L146) | Cloud Scheduler jobs to trigger this workflow. Map keys are job names. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_account](variables.tf#L182) | The service account email to run the workflow as. Ignored if service_account_create is true. | <code>string</code> |  | <code>null</code> |
| [service_account_create](variables.tf#L188) | Whether to create a dedicated service account for this workflow. | <code>bool</code> |  | <code>false</code> |
| [service_account_roles](variables.tf#L194) | List of IAM roles to grant to the created service account. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [source_contents](variables.tf#L200) | Workflow code to be executed (YAML or JSON string). | <code>string</code> |  | <code>&#34;&#60;&#60;-EOT&#8230;EOT&#34;</code> |
| [task_queues](variables.tf#L212) | Cloud Tasks queues to create for this workflow. Map keys are queue names. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [user_env_vars](variables.tf#L256) | User-defined environment variables associated with this workflow revision. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [eventarc_trigger_ids](outputs.tf#L15) | Map of Eventarc trigger IDs keyed by trigger name. |  |
| [eventarc_triggers](outputs.tf#L20) | Eventarc trigger resources. |  |
| [id](outputs.tf#L25) | The workflow ID. |  |
| [name](outputs.tf#L34) | The workflow name. |  |
| [revision_id](outputs.tf#L39) | The revision ID of the workflow. |  |
| [scheduler_job_ids](outputs.tf#L44) | Map of Cloud Scheduler job IDs keyed by job name. |  |
| [scheduler_jobs](outputs.tf#L49) | Cloud Scheduler job resources. |  |
| [service_account](outputs.tf#L54) | The service account email used for execution. |  |
| [service_account_email](outputs.tf#L59) | The email of the created service account. |  |
| [task_queue_ids](outputs.tf#L64) | Map of Cloud Tasks queue IDs keyed by queue name. |  |
| [task_queues](outputs.tf#L69) | Cloud Tasks queue resources. |  |
| [workflow](outputs.tf#L74) | The workflow resource. |  |
<!-- END TFDOC -->
