# Google Cloud Workflows Module

This module manages Google Cloud Workflows, providing end-to-end support for serverless workflow orchestration, execution call logging, environment variables, revisions, dedicated Service Account creation, Cloud Tasks queues, Cloud Scheduler jobs, and Eventarc triggers.

<!-- BEGIN TOC -->
- [Basic Workflow](#basic-workflow)
- [Workflow with Dedicated Service Account and Call Logging](#workflow-with-dedicated-service-account-and-call-logging)
- [Workflow with Scheduled Execution (Cloud Scheduler)](#workflow-with-scheduled-execution-cloud-scheduler)
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
  service_account = {
    create = true
    roles  = ["roles/logging.logWriter"]
  }
  env_vars = {
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

## Workflow with Scheduled Execution (Cloud Scheduler)

```hcl
module "workflow_scheduled" {
  source     = "./fabric/modules/workflows"
  project_id = var.project_id
  name       = "scheduled-workflow"
  region     = "europe-west1"
  service_account = {
    email = "custom-sa@${var.project_id}.iam.gserviceaccount.com"
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
# tftest modules=1 resources=2
```

## Workflow with Cloud Tasks Queue

```hcl
module "workflow_with_queue" {
  source     = "./fabric/modules/workflows"
  project_id = var.project_id
  name       = "tasks-workflow"
  region     = "us-central1"
  crypto_key_name = format(
    "projects/%s/locations/us-central1/keyRings/my-ring/cryptoKeys/my-key",
    var.project_id
  )
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
  source     = "./fabric/modules/workflows"
  project_id = var.project_id
  name       = "eventarc-workflow"
  region     = "europe-west1"
  service_account = {
    create = true
  }
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
| [name](variables.tf#L114) | Name of the Workflow. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L129) | The ID of the project in which the resource belongs. | <code>string</code> | ✓ |  |
| [region](variables.tf#L134) | The region of the workflow. | <code>string</code> | ✓ |  |
| [call_log_level](variables.tf#L15) | Describes the level of platform logging to apply to calls and call responses during executions of this workflow. | <code>string</code> |  | <code>null</code> |
| [context](variables.tf#L31) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [crypto_key_name](variables.tf#L44) | The KMS key name used to encrypt workflow data at rest. | <code>string</code> |  | <code>null</code> |
| [deletion_protection](variables.tf#L50) | Whether deletion protection is enabled for this workflow. | <code>bool</code> |  | <code>false</code> |
| [description](variables.tf#L56) | Description of the workflow. | <code>string</code> |  | <code>null</code> |
| [env_vars](variables.tf#L62) | User-defined environment variables associated with this workflow revision. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [eventarc_triggers](variables.tf#L68) | Eventarc triggers that invoke this workflow. Map keys are trigger names. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [execution_history_level](variables.tf#L89) | Describes the level of execution history to apply to executions of this workflow. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L108) | A set of key/value label pairs to assign to this Workflow. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L119) | Optional prefix used for resource names. | <code>string</code> |  | <code>null</code> |
| [scheduler_jobs](variables.tf#L139) | Cloud Scheduler jobs to trigger this workflow. Map keys are job names. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_account](variables.tf#L175) | Service account configuration. If create is true, a dedicated service account is created and granted roles on the workflow's project (project_id). | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [source_contents](variables.tf#L187) | Workflow code to be executed (YAML or JSON string). | <code>string</code> |  | <code>&#34;&#60;&#60;-EOT&#8230;EOT&#34;</code> |
| [tags](variables.tf#L199) | Resource management tags. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [task_queues](variables.tf#L205) | Cloud Tasks queues to create for this workflow. Map keys are queue names. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [eventarc_trigger_ids](outputs.tf#L15) | Map of Eventarc trigger IDs keyed by trigger name. |  |
| [eventarc_triggers](outputs.tf#L20) | Eventarc trigger resources. |  |
| [id](outputs.tf#L25) | The workflow ID. |  |
| [name](outputs.tf#L33) | The workflow name. |  |
| [revision_id](outputs.tf#L38) | The revision ID of the workflow. |  |
| [scheduler_job_ids](outputs.tf#L43) | Map of Cloud Scheduler job IDs keyed by job name. |  |
| [scheduler_jobs](outputs.tf#L48) | Cloud Scheduler job resources. |  |
| [service_account](outputs.tf#L53) | Service account resource. |  |
| [service_account_email](outputs.tf#L58) | Service account email. |  |
| [service_account_iam_email](outputs.tf#L63) | Service account IAM-format email. |  |
| [task_queue_ids](outputs.tf#L72) | Map of Cloud Tasks queue IDs keyed by queue name. |  |
| [task_queues](outputs.tf#L77) | Cloud Tasks queue resources. |  |
| [workflow](outputs.tf#L82) | The workflow resource. |  |
<!-- END TFDOC -->
