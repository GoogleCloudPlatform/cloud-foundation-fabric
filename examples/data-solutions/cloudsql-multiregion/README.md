# Cloud SQL instance with multi-region read replicas

This example creates a [Cloud SQL instance](https://cloud.google.com/sql) with multi-region read replicas as described in the [Cloud SQL for PostgreSQL disaster recovery](https://cloud.google.com/architecture/cloud-sql-postgres-disaster-recovery-complete-failover-fallback) article.

The solution is resilient to a regional outage. To get familiar with the procedure needed in the unfortunate case of a disaster recovery, please follow steps described in [part two](https://cloud.google.com/architecture/cloud-sql-postgres-disaster-recovery-complete-failover-fallback#phase-2) of the aforementioned article.

The solution will use:
- A VPC with Private Service Access to deploy the instances
- Postgre SQL instanced with Private IP

This is the high level diagram:

![Cloud SQL multi-region.](diagram.png "Cloud SQL multi-region")

# Requirements

This example will deploy all its resources into the project defined by the `project_id` variable. Please note that we assume this project already exists. However, if you provide the appropriate values to the `project_create` variable, the project will be created as part of the deployment.

If `project_create` is left to `null`, the identity performing the deployment needs the `owner` role on the project defined by the `project_id` variable. Otherwise, the identity performing the deployment needs `resourcemanager.projectCreator` on the resource hierarchy node specified by `project_create.parent` and `billing.user` on the billing account specified by `project_create.billing_account_id`.


## Deployment

Configure the Terraform variables in your `terraform.tfvars` file. You need to specify at least the `project_id` and `prefix` variables. See  [`terraform.tfvars.sample`](terraform.tfvars.sample) as starting point.

Run Terraform init:

```
$ terraform init
$ terraform apply
```

You should see the output of the Terraform script with resources created and some commands that you'll need in the following steps below.

TBC

## Move to real use case consideration

This implementation is intentionally minimal and easy to read. A real world use case should consider:
 - Using a Shared VPC
 - Using VPC-SC to mitigate data exfiltration
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [postgres_user_password](variables.tf#L29) | `postgres` user password. | <code>string</code> | ✓ |  |
| [prefix](variables.tf#L40) | Unique prefix used for resource names. Not used for project if 'project_create' is null. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L54) | Project id, references existing project if `project_create` is null. | <code>string</code> | ✓ |  |
| [cmek_encryption](variables.tf#L17) | Flag to enable CMEK on GCP resources created. | <code>bool</code> |  | <code>false</code> |
| [data_eng_principals](variables.tf#L23) | Groups with Service Account Token creator role on service accounts in IAM format, only user supported on CloudSQL, eg 'user@domain.com'. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [postgres_databases](variables.tf#L34) | `postgres` databases. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#34;guestbook&#34;&#93;</code> |
| [project_create](variables.tf#L45) | Provide values if project creation is needed, uses existing project if null. Parent is in 'folders/nnn' or 'organizations/nnn' format. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  parent             &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [regions](variables.tf#L59) | Map of instance_name => location where instances will be deployed. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  primary &#61; &#34;europe-west1&#34;&#10;  replica &#61; &#34;europe-west3&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [sql_configuration](variables.tf#L73) | Cloud SQL configuration | <code title="object&#40;&#123;&#10;  availability_type &#61; string&#10;  database_version  &#61; string&#10;  psa_range         &#61; string&#10;  tier              &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  availability_type &#61; &#34;REGIONAL&#34;&#10;  database_version  &#61; &#34;POSTGRES_13&#34;&#10;  psa_range         &#61; &#34;10.60.0.0&#47;16&#34;&#10;  tier              &#61; &#34;db-g1-small&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [connection_names](outputs.tf#L17) | Connection name of each instance. |  |
| [ips](outputs.tf#L22) | IP address of each instance. |  |
| [project_id](outputs.tf#L27) | ID of the project containing all the instances. |  |

<!-- END TFDOC -->
