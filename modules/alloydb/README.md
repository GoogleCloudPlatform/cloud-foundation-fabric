# AlloyDB module

This module manages the creation of an AlloyDB cluster and instance with potential read replicas and an advanced cross region replication setup for disaster recovery scenarios. 
It can also create an initial set of users via the `users` parameters.

Note that this module assumes that some options are the same for both the primary instance and the secondary one in case of cross regional replication configuration.

*Warning:* if you use the `users` field, you terraform state will contain each user's password in plain text.

<!-- TOC -->
* [AlloyDB module](#alloydb-module)
  * [Examples](#examples)
    * [Simple example](#simple-example)
    * [Cross region replication](#cross-region-replication)
  * [Variables](#variables)
  * [Outputs](#outputs)
<!-- TOC -->

## Examples
### Simple example

This example shows how to setup a project, VPC and AlloyDB cluster and instance.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  parent          = var.folder_id
  name            = "alloydb-prj"
  prefix          = var.prefix
  services = [
    "servicenetworking.googleapis.com",
    "alloydb.googleapis.com",
  ]
}

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = module.project.project_id
  name       = "my-network"
  # need only one - psa_config or subnets_psc
  psa_configs = [{
    ranges          = { alloydb = "10.60.0.0/16" }
    deletion_policy = "ABANDON"
  }]
  subnets_psc = [
    {
      ip_cidr_range = "10.0.3.0/24"
      name          = "psc"
      region        = var.region
    }
  ]
}

module "alloydb" {
  source       = "./fabric/modules/alloydb"
  project_id   = module.project.project_id
  cluster_name = "db"
  cluster_network_config = {
    network = module.vpc.id
  }
  name     = "db"
  location = var.region
}
# tftest modules=3 resources=14 inventory=simple.yaml e2e
```

### Cross region replication

```hcl
module "alloydb" {
  source       = "./fabric/modules/alloydb"
  project_id   = var.project_id
  cluster_name = "db"
  cluster_network_config = {
    network = var.vpc.self_link
  }
  name     = "db"
  location = "europe-west8"
  cross_region_replication = {
    enabled = true
    region  = "europe-west12"
  }
}
# tftest modules=1 resources=4 inventory=cross_region_replication.yaml e2e
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cluster_name](variables.tf#L85) | Name of the primary cluster. | <code>string</code> | ✓ |  |
| [cluster_network_config](variables.tf#L90) | Network configuration for the cluster. Only one between cluster_network_config and cluster_psc_config can be used. | <code title="object&#40;&#123;&#10;  network            &#61; string&#10;  allocated_ip_range &#61; optional&#40;string, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [location](variables.tf#L196) | Region or zone of the cluster and instance. | <code>string</code> | ✓ |  |
| [name](variables.tf#L252) | Name of primary instance. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L267) | The ID of the project where this instances will be created. | <code>string</code> | ✓ |  |
| [automated_backup_configuration](variables.tf#L17) | Automated backup settings for cluster. | <code title="object&#40;&#123;&#10;  enabled       &#61; optional&#40;bool, false&#41;&#10;  backup_window &#61; optional&#40;string, &#34;1800s&#34;&#41;&#10;  location      &#61; optional&#40;string&#41;&#10;  weekly_schedule &#61; optional&#40;object&#40;&#123;&#10;    days_of_week &#61; optional&#40;list&#40;string&#41;, &#91;&#10;      &#34;MONDAY&#34;, &#34;TUESDAY&#34;, &#34;WEDNESDAY&#34;, &#34;THURSDAY&#34;, &#34;FRIDAY&#34;, &#34;SATURDAY&#34;, &#34;SUNDAY&#34;&#10;    &#93;&#41;&#10;    start_times &#61; optional&#40;object&#40;&#123;&#10;      hours   &#61; optional&#40;number, 23&#41;&#10;      minutes &#61; optional&#40;number, 0&#41;&#10;      seconds &#61; optional&#40;number, 0&#41;&#10;      nanos   &#61; optional&#40;number, 0&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  retention_count  &#61; optional&#40;number, 7&#41;&#10;  retention_period &#61; optional&#40;string, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled       &#61; false&#10;  backup_window &#61; &#34;1800s&#34;&#10;  location      &#61; null&#10;  weekly_schedule &#61; &#123;&#10;    days_of_week &#61; &#91;&#34;MONDAY&#34;, &#34;TUESDAY&#34;, &#34;WEDNESDAY&#34;, &#34;THURSDAY&#34;, &#34;FRIDAY&#34;, &#34;SATURDAY&#34;, &#34;SUNDAY&#34;&#93;&#10;    start_times &#61; &#123;&#10;      hours   &#61; 23&#10;      minutes &#61; 0&#10;      seconds &#61; 0&#10;      nanos   &#61; 0&#10;    &#125;&#10;  &#125;&#10;  retention_count  &#61; 7&#10;  retention_period &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [availability_type](variables.tf#L68) | Availability type for the primary replica. Either `ZONAL` or `REGIONAL`. | <code>string</code> |  | <code>&#34;REGIONAL&#34;</code> |
| [client_connection_config](variables.tf#L74) | Client connection config. | <code title="object&#40;&#123;&#10;  require_connectors &#61; optional&#40;bool, false&#41;&#10;  ssl_config &#61; optional&#40;object&#40;&#123;&#10;    ssl_mode &#61; string&#10;  &#125;&#41;, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [continuous_backup_configuration](variables.tf#L99) | Continuous backup settings for cluster. | <code title="object&#40;&#123;&#10;  enabled              &#61; optional&#40;bool, false&#41;&#10;  recovery_window_days &#61; optional&#40;number, 14&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled              &#61; false&#10;  recovery_window_days &#61; 14&#10;&#125;">&#123;&#8230;&#125;</code> |
| [cross_region_replication](variables.tf#L112) | Cross region replication config. | <code title="object&#40;&#123;&#10;  enabled           &#61; optional&#40;bool, false&#41;&#10;  promote_secondary &#61; optional&#40;bool, false&#41;&#10;  region            &#61; optional&#40;string, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [database_version](variables.tf#L126) | Database type and version to create. | <code>string</code> |  | <code>&#34;POSTGRES_15&#34;</code> |
| [deletion_policy](variables.tf#L132) | AlloyDB cluster and instance deletion policy. | <code>string</code> |  | <code>null</code> |
| [encryption_config](variables.tf#L138) | Set encryption configuration. KMS name format: 'projects/[PROJECT]/locations/[REGION]/keyRings/[RING]/cryptoKeys/[KEY_NAME]'. | <code title="object&#40;&#123;&#10;  primary_kms_key_name   &#61; string&#10;  secondary_kms_key_name &#61; optional&#40;string, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [flags](variables.tf#L148) | Map FLAG_NAME=>VALUE for database-specific tuning. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [initial_user](variables.tf#L155) | AlloyDB cluster initial user credentials. | <code title="object&#40;&#123;&#10;  user     &#61; optional&#40;string, &#34;root&#34;&#41;&#10;  password &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [insights_config](variables.tf#L164) | Query Insights configuration. Defaults to null which disables Query Insights. | <code title="object&#40;&#123;&#10;  query_string_length     &#61; optional&#40;number, 1024&#41;&#10;  record_application_tags &#61; optional&#40;bool, false&#41;&#10;  record_client_address   &#61; optional&#40;bool, false&#41;&#10;  query_plans_per_minute  &#61; optional&#40;number, 5&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [instance_network_config](variables.tf#L175) | Network configuration for the instance. Only one between instance_network_config and instance_psc_config can be used. | <code title="object&#40;&#123;&#10;  authorized_external_networks &#61; list&#40;string&#41;&#10;  enable_public_ip             &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [labels](variables.tf#L190) | Labels to be attached to all instances. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [machine_config](variables.tf#L201) | AlloyDB machine config. | <code title="object&#40;&#123;&#10;  cpu_count &#61; optional&#40;number, 2&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  cpu_count &#61; 2&#10;&#125;">&#123;&#8230;&#125;</code> |
| [maintenance_config](variables.tf#L212) | Set maintenance window configuration. | <code title="object&#40;&#123;&#10;  enabled &#61; optional&#40;bool, false&#41;&#10;  day     &#61; optional&#40;string, &#34;SUNDAY&#34;&#41;&#10;  start_time &#61; optional&#40;object&#40;&#123;&#10;    hours   &#61; optional&#40;number, 23&#41;&#10;    minutes &#61; optional&#40;number, 0&#41;&#10;    seconds &#61; optional&#40;number, 0&#41;&#10;    nanos   &#61; optional&#40;number, 0&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled &#61; false&#10;  day     &#61; &#34;SUNDAY&#34;&#10;  start_time &#61; &#123;&#10;    hours   &#61; 23&#10;    minutes &#61; 0&#10;    seconds &#61; 0&#10;    nanos   &#61; 0&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [prefix](variables.tf#L257) | Optional prefix used to generate instance names. | <code>string</code> |  | <code>null</code> |
| [query_insights_config](variables.tf#L272) | Query insights config. | <code title="object&#40;&#123;&#10;  query_string_length     &#61; optional&#40;number, 1024&#41;&#10;  record_application_tags &#61; optional&#40;bool, true&#41;&#10;  record_client_address   &#61; optional&#40;bool, true&#41;&#10;  query_plans_per_minute  &#61; optional&#40;number, 5&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  query_string_length     &#61; 1024&#10;  record_application_tags &#61; true&#10;  record_client_address   &#61; true&#10;  query_plans_per_minute  &#61; 5&#10;&#125;">&#123;&#8230;&#125;</code> |
| [users](variables.tf#L288) | Map of users to create in the primary instance (and replicated to other replicas). Set PASSWORD to null if you want to get an autogenerated password. The user types available are: 'ALLOYDB_BUILT_IN' or 'ALLOYDB_IAM_USER'. | <code title="map&#40;object&#40;&#123;&#10;  password &#61; optional&#40;string&#41;&#10;  roles    &#61; optional&#40;list&#40;string&#41;, &#91;&#34;alloydbsuperuser&#34;&#93;&#41;&#10;  type     &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L25) | Fully qualified primary instance id. |  |
| [ids](outputs.tf#L30) | Fully qualified ids of all instances. |  |
| [instances](outputs.tf#L38) | AlloyDB instance resources. | ✓ |
| [ip](outputs.tf#L44) | IP address of the primary instance. |  |
| [ips](outputs.tf#L49) | IP addresses of all instances. |  |
| [name](outputs.tf#L56) | Name of the primary instance. |  |
| [names](outputs.tf#L61) | Names of all instances. |  |
| [user_passwords](outputs.tf#L69) | Map of containing the password of all users created through terraform. | ✓ |
<!-- END TFDOC -->
