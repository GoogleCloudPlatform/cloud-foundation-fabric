# BigQuery Connection

This module allows creating a BigQuery connection.

<!-- BEGIN TOC -->
- [Cloud SQL Connection](#cloud-sql-connection)
- [Cloud SQL Connection with Cloud KMS](#cloud-sql-connection-with-cloud-kms)
- [Spanner Connection](#spanner-connection)
- [Spanner Connection with Context interpolations](#spanner-connection-with-context-interpolations)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Cloud SQL Connection

```hcl
module "bigquery-connection" {
  source        = "./fabric/modules/bigquery-connection"
  project_id    = var.project_id
  location      = "EU"
  connection_id = "my-connection"
  friendly_name = "My Cloud SQL Connection"
  description   = "A connection to a Cloud SQL instance."

  connection_config = {
    cloud_sql = {
      instance_id = "my-instance-id"
      database    = "my-database"
      type        = "POSTGRES"
      credential = {
        username = "my-username"
        password = "my-password"
      }
    }
  }
  iam = {
    "roles/bigquery.connectionUser" = ["user:my-user@example.com"]
  }
}
# tftest modules=1 resources=2 inventory=cloudsql.yaml
```

## Cloud SQL Connection with Cloud KMS

```hcl
module "bigquery-connection" {
  source         = "./fabric/modules/bigquery-connection"
  project_id     = var.project_id
  location       = "EU"
  connection_id  = "my-connection"
  friendly_name  = "My BigQuery Connection"
  description    = "A connection to a Cloud SQL instance."
  encryption_key = "my-key"

  connection_config = {
    cloud_sql = {
      instance_id = "my-instance-id"
      database    = "my-database"
      type        = "POSTGRES"
      credential = {
        username = "my-username"
        password = "my-password"
      }
    }
  }
}
# tftest modules=1 resources=1 inventory=cloudsql_kms.yaml
```

## Spanner Connection

```hcl
module "bigquery-connection" {
  source        = "./fabric/modules/bigquery-connection"
  project_id    = var.project_id
  location      = "EU"
  connection_id = "my-connection"
  friendly_name = "My BigQuery Connection"
  description   = "A connection to a Spanner instance."

  connection_config = {
    cloud_spanner = {
      database        = "projects/my-project/instances/my-instance/databases/my-database"
      use_parallelism = true
      use_data_boost  = true
      max_parallelism = 2
    }
  }
  iam = {
    "roles/bigquery.connectionUser" = ["user:my-user@example.com"]
  }
}
# tftest modules=1 resources=2 inventory=spanner.yaml
```

## Spanner Connection with Context interpolations

```hcl
module "bigquery-connection" {
  source        = "./fabric/modules/bigquery-connection"
  project_id    = var.project_id
  location      = "EU"
  connection_id = "my-connection"
  friendly_name = "My BigQuery Connection"
  description   = "A connection to a Spanner instance."

  connection_config = {
    cloud_spanner = {
      database        = "projects/my-project/instances/my-instance/databases/my-database"
      use_parallelism = true
      use_data_boost  = true
      max_parallelism = 2
    }
  }
  context = {
    iam_principals = {
      myuser = "user:my-user@example.com"
    }
  }
  iam = {
    "roles/bigquery.connectionUser" = ["$iam_principals:myuser"]
  }
}
# tftest modules=1 resources=2 inventory=spanner_context.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [connection_id](variables.tf#L59) | The ID of the connection. | <code>string</code> | ✓ |  |
| [location](variables.tf#L132) | The geographic location where the connection should reside. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L137) | The ID of the project in which the resource belongs. | <code>string</code> | ✓ |  |
| [connection_config](variables.tf#L17) | Connection properties. | <code title="object&#40;&#123;&#10;  cloud_sql &#61; optional&#40;object&#40;&#123;&#10;    instance_id &#61; string&#10;    database    &#61; string&#10;    type        &#61; string&#10;    credential &#61; object&#40;&#123;&#10;      username &#61; string&#10;      password &#61; string&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;  aws &#61; optional&#40;object&#40;&#123;&#10;    access_role &#61; object&#40;&#123;&#10;      iam_role_id &#61; string&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;  azure &#61; optional&#40;object&#40;&#123;&#10;    customer_tenant_id              &#61; string&#10;    federated_application_client_id &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  cloud_spanner &#61; optional&#40;object&#40;&#123;&#10;    database        &#61; string&#10;    use_parallelism &#61; optional&#40;bool&#41;&#10;    use_data_boost  &#61; optional&#40;bool&#41;&#10;    max_parallelism &#61; optional&#40;number&#41;&#10;    database_role   &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  cloud_resource &#61; optional&#40;object&#40;&#123;&#10;  &#125;&#41;&#41;&#10;  spark &#61; optional&#40;object&#40;&#123;&#10;    metastore_service_config &#61; optional&#40;object&#40;&#123;&#10;      metastore_service &#61; string&#10;    &#125;&#41;&#41;&#10;    spark_history_server_config &#61; optional&#40;object&#40;&#123;&#10;      dataproc_cluster &#61; string&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L64) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  iam_principals &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L73) | A description of the connection. | <code>string</code> |  | <code>null</code> |
| [encryption_key](variables.tf#L79) | The name of the KMS key used for encryption. | <code>string</code> |  | <code>null</code> |
| [friendly_name](variables.tf#L85) | A descriptive name for the connection. | <code>string</code> |  | <code>null</code> |
| [iam](variables.tf#L91) | IAM bindings for the connection in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L97) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L111) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables.tf#L125) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [connection_config](outputs.tf#L17) | The connection configuration. |  |
| [connection_id](outputs.tf#L29) | The ID of the BigQuery connection. |  |
| [description](outputs.tf#L34) | The description of the connection. |  |
| [location](outputs.tf#L39) | The location of the connection. |  |
<!-- END TFDOC -->
