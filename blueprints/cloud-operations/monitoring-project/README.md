# Monitoring Project Blueprint

This blueprint creates a centralized monitoring project that can be used to monitor resources across your Google Cloud environment. The blueprint sets up a dedicated project with Cloud Monitoring and creates pre-configured dashboards and alert policies.

![Monitoring Project Architecture](diagram.png)

## Features

- Creates a dedicated monitoring project
- Sets up essential monitoring services
- Configures pre-built dashboards for VM monitoring
- Creates alert policies for common metrics like CPU utilization and disk usage
- Configures notification channels (optional)

## Usage

Basic usage:

```hcl
module "monitoring_project" {
  source          = "./fabric/blueprints/cloud-operations/monitoring-project"
  project_id      = "my-monitoring-project"
  billing_account = "ABCDEF-123456-GHIJKL"
  parent          = "folders/123456789"
}
```

With notification channels:

```hcl
module "monitoring_project" {
  source                      = "./fabric/blueprints/cloud-operations/monitoring-project"
  project_id                  = "my-monitoring-project"
  billing_account             = "ABCDEF-123456-GHIJKL"
  parent                      = "folders/123456789"
  create_notification_channels = true
  notification_email          = "alerts@example.com"
}
```

## Monitoring Resources

This blueprint creates the following monitoring resources:

### Dashboards

- **VM Instances Overview**: Dashboard showing CPU, memory, disk, and network metrics for VM instances.

### Alert Policies

- **High CPU Utilization**: Alerts when CPU utilization exceeds 80% for more than 1 minute.
- **High Disk Usage**: Alerts when disk usage exceeds 90% for more than 5 minutes.

## Monitoring Best Practices

- Use this project as a centralized location for monitoring across multiple projects
- Configure appropriate IAM permissions to allow the necessary users access to monitoring data
- Set up scoping to monitor projects across your organization
- Consider integrating with external monitoring systems if needed

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [billing_account](variables.tf#L17) | Billing account id used for the project. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L30) | Project id for the monitoring project. | <code>string</code> | ✓ |  |
| [create_alert_policies](variables.tf#L53) | Create alert policies for common metrics. | <code>bool</code> |  | <code>true</code> |
| [create_dashboards](variables.tf#L59) | Create monitoring dashboards. | <code>bool</code> |  | <code>true</code> |
| [create_notification_channels](variables.tf#L41) | Create notification channels for alerts. | <code>bool</code> |  | <code>false</code> |
| [notification_email](variables.tf#L47) | Email address for notifications. | <code>string</code> |  | <code>null</code> |
| [parent](variables.tf#L23) | Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format. | <code>string</code> |  | <code>null</code> |
| [project_create](variables.tf#L35) | Create project. When set to false, uses a data source to reference existing project. | <code>bool</code> |  | <code>true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [alert_policies](outputs.tf#L28) | Alert policies created. |  |
| [dashboards](outputs.tf#L36) | Dashboards created. |  |
| [notification_channels](outputs.tf#L21) | Notification channels created. |  |
| [project_id](outputs.tf#L17) | Monitoring project ID. |  |
<!-- END TFDOC -->

## Test

```hcl
module "test" {
  source          = "./fabric/blueprints/cloud-operations/monitoring-project"
  project_id      = "test-monitoring-project"
  billing_account = "ABCDEF-123456-GHIJKL"
  parent          = "folders/123456789"
}
# tftest modules=4 resources=4
```