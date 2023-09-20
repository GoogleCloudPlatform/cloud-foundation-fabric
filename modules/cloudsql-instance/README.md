# Cloud SQL instance with read replicas

This module manages the creation of Cloud SQL instances with potential read replicas in other regions. It can also create an initial set of users and databases via the `users` and `databases` parameters.

Note that this module assumes that some options are the same for both the primary instance and all the replicas (e.g. tier, disks, labels, flags, etc).

*Warning:* if you use the `users` field, you terraform state will contain each user's password in plain text.

## Simple example

This example shows how to setup a project, VPC and a standalone Cloud SQL instance.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  parent          = var.organization_id
  name            = "my-db-project"
  services = [
    "servicenetworking.googleapis.com"
  ]
}

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = module.project.project_id
  name       = "my-network"
  psa_config = {
    ranges = { cloud-sql = "10.60.0.0/16" }
  }
}

module "db" {
  source           = "./fabric/modules/cloudsql-instance"
  project_id       = module.project.project_id
  network          = module.vpc.self_link
  name             = "db"
  region           = "europe-west1"
  database_version = "POSTGRES_13"
  tier             = "db-g1-small"
}
# tftest modules=3 resources=11 inventory=simple.yaml
```

## Cross-regional read replica

```hcl
module "db" {
  source           = "./fabric/modules/cloudsql-instance"
  project_id       = var.project_id
  network          = var.vpc.self_link
  prefix           = "myprefix"
  name             = "db"
  region           = "europe-west1"
  database_version = "POSTGRES_13"
  tier             = "db-g1-small"

  replicas = {
    replica1 = { region = "europe-west3", encryption_key_name = null }
    replica2 = { region = "us-central1", encryption_key_name = null }
  }
}
# tftest modules=1 resources=3 inventory=replicas.yaml
```

## Custom flags, databases and users

```hcl
module "db" {
  source           = "./fabric/modules/cloudsql-instance"
  project_id       = var.project_id
  network          = var.vpc.self_link
  name             = "db"
  region           = "europe-west1"
  database_version = "MYSQL_8_0"
  tier             = "db-g1-small"

  flags = {
    disconnect_on_expired_password = "on"
  }

  databases = [
    "people",
    "departments"
  ]

  users = {
    # generatea password for user1
    user1 = null
    # assign a password to user2
    user2 = "mypassword"
  }
}
# tftest modules=1 resources=6 inventory=custom.yaml
```

### CMEK encryption
```hcl

module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  parent          = var.organization_id
  name            = "my-db-project"
  services = [
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
  ]
}

module "kms" {
  source     = "./fabric/modules/kms"
  project_id = module.project.project_id
  keyring = {
    name     = "keyring"
    location = var.region
  }
  keys = {
    key-sql = {
      iam = {
        "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
          "serviceAccount:${module.project.service_accounts.robots.sqladmin}"
        ]
      }
    }
  }
}

module "db" {
  source              = "./fabric/modules/cloudsql-instance"
  project_id          = module.project.project_id
  encryption_key_name = module.kms.keys["key-sql"].id
  network             = var.vpc.self_link
  name                = "db"
  region              = var.region
  database_version    = "POSTGRES_13"
  tier                = "db-g1-small"
}

# tftest modules=3 resources=10
```

### Enable public IP

Use `ipv_enabled` to create instances with a public IP.

```hcl
module "db" {
  source           = "./fabric/modules/cloudsql-instance"
  project_id       = var.project_id
  network          = var.vpc.self_link
  name             = "db"
  region           = "europe-west1"
  tier             = "db-g1-small"
  database_version = "MYSQL_8_0"
  ipv4_enabled     = true
  replicas = {
    replica1 = { region = "europe-west3", encryption_key_name = null }
  }
}
# tftest modules=1 resources=2 inventory=public-ip.yaml
```

### Query Insights

Provide `insights_config` (can be just empty `{}`) to enable [Query Insights](https://cloud.google.com/sql/docs/postgres/using-query-insights)

```hcl
module "db" {
  source           = "./fabric/modules/cloudsql-instance"
  project_id       = var.project_id
  network          = var.vpc.self_link
  name             = "db"
  region           = "europe-west1"
  database_version = "POSTGRES_13"
  tier             = "db-g1-small"

  insights_config = {
    query_string_length = 2048
  }
}
# tftest modules=1 resources=1 inventory=insights.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [database_version](variables.tf#L71) | Database type and version to create. | <code>string</code> | ✓ |  |
| [name](variables.tf#L141) | Name of primary instance. | <code>string</code> | ✓ |  |
| [network](variables.tf#L146) | VPC self link where the instances will be deployed. Private Service Networking must be enabled and configured in this VPC. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L167) | The ID of the project where this instances will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L172) | Region of the primary instance. | <code>string</code> | ✓ |  |
| [tier](variables.tf#L198) | The machine type to use for the instances. | <code>string</code> | ✓ |  |
| [activation_policy](variables.tf#L16) | This variable specifies when the instance should be active. Can be either ALWAYS, NEVER or ON_DEMAND. Default is ALWAYS. | <code>string</code> |  | <code>&#34;ALWAYS&#34;</code> |
| [allocated_ip_ranges](variables.tf#L27) | (Optional)The name of the allocated ip range for the private ip CloudSQL instance. For example: \"google-managed-services-default\". If set, the instance ip will be created in the allocated range. The range name must comply with RFC 1035. Specifically, the name must be 1-63 characters long and match the regular expression a-z?. | <code title="object&#40;&#123;&#10;  primary &#61; optional&#40;string&#41;&#10;  replica &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [authorized_networks](variables.tf#L36) | Map of NAME=>CIDR_RANGE to allow to connect to the database(s). | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [availability_type](variables.tf#L42) | Availability type for the primary replica. Either `ZONAL` or `REGIONAL`. | <code>string</code> |  | <code>&#34;ZONAL&#34;</code> |
| [backup_configuration](variables.tf#L48) | Backup settings for primary instance. Will be automatically enabled if using MySQL with one or more replicas. | <code title="object&#40;&#123;&#10;  enabled                        &#61; optional&#40;bool, false&#41;&#10;  binary_log_enabled             &#61; optional&#40;bool, false&#41;&#10;  start_time                     &#61; optional&#40;string, &#34;23:00&#34;&#41;&#10;  location                       &#61; optional&#40;string&#41;&#10;  log_retention_days             &#61; optional&#40;number, 7&#41;&#10;  point_in_time_recovery_enabled &#61; optional&#40;bool&#41;&#10;  retention_count                &#61; optional&#40;number, 7&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled                        &#61; false&#10;  binary_log_enabled             &#61; false&#10;  start_time                     &#61; &#34;23:00&#34;&#10;  location                       &#61; null&#10;  log_retention_days             &#61; 7&#10;  point_in_time_recovery_enabled &#61; null&#10;  retention_count                &#61; 7&#10;&#125;">&#123;&#8230;&#125;</code> |
| [databases](variables.tf#L76) | Databases to create once the primary instance is created. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [deletion_protection](variables.tf#L82) | Allow terraform to delete instances. | <code>bool</code> |  | <code>false</code> |
| [deletion_protection_enabled](variables.tf#L88) | Set Google's deletion protection attribute which applies across all surfaces (UI, API, & Terraform). | <code>bool</code> |  | <code>false</code> |
| [disk_size](variables.tf#L94) | Disk size in GB. Set to null to enable autoresize. | <code>number</code> |  | <code>null</code> |
| [disk_type](variables.tf#L100) | The type of data disk: `PD_SSD` or `PD_HDD`. | <code>string</code> |  | <code>&#34;PD_SSD&#34;</code> |
| [encryption_key_name](variables.tf#L106) | The full path to the encryption key used for the CMEK disk encryption of the primary instance. | <code>string</code> |  | <code>null</code> |
| [flags](variables.tf#L112) | Map FLAG_NAME=>VALUE for database-specific tuning. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [insights_config](variables.tf#L118) | Query Insights configuration. Defaults to null which disables Query Insights. | <code title="object&#40;&#123;&#10;  query_string_length     &#61; optional&#40;number, 1024&#41;&#10;  record_application_tags &#61; optional&#40;bool, false&#41;&#10;  record_client_address   &#61; optional&#40;bool, false&#41;&#10;  query_plans_per_minute  &#61; optional&#40;number, 5&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [ipv4_enabled](variables.tf#L129) | Add a public IP address to database instance. | <code>bool</code> |  | <code>false</code> |
| [labels](variables.tf#L135) | Labels to be attached to all instances. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [postgres_client_certificates](variables.tf#L151) | Map of cert keys connect to the application(s) using public IP. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [prefix](variables.tf#L157) | Optional prefix used to generate instance names. | <code>string</code> |  | <code>null</code> |
| [replicas](variables.tf#L177) | Map of NAME=> {REGION, KMS_KEY} for additional read replicas. Set to null to disable replica creation. | <code title="map&#40;object&#40;&#123;&#10;  region              &#61; string&#10;  encryption_key_name &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [require_ssl](variables.tf#L186) | Enable SSL connections only. | <code>bool</code> |  | <code>null</code> |
| [root_password](variables.tf#L192) | Root password of the Cloud SQL instance. Required for MS SQL Server. | <code>string</code> |  | <code>null</code> |
| [users](variables.tf#L203) | Map of users to create in the primary instance (and replicated to other replicas) in the format USER=>PASSWORD. For MySQL, anything afterr the first `@` (if persent) will be used as the user's host. Set PASSWORD to null if you want to get an autogenerated password. | <code>map&#40;string&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [connection_name](outputs.tf#L24) | Connection name of the primary instance. |  |
| [connection_names](outputs.tf#L29) | Connection names of all instances. |  |
| [id](outputs.tf#L37) | Fully qualified primary instance id. |  |
| [ids](outputs.tf#L42) | Fully qualified ids of all instances. |  |
| [instances](outputs.tf#L50) | Cloud SQL instance resources. | ✓ |
| [ip](outputs.tf#L56) | IP address of the primary instance. |  |
| [ips](outputs.tf#L61) | IP addresses of all instances. |  |
| [name](outputs.tf#L69) | Name of the primary instance. |  |
| [names](outputs.tf#L74) | Names of all instances. |  |
| [postgres_client_certificates](outputs.tf#L82) | The CA Certificate used to connect to the SQL Instance via SSL. | ✓ |
| [self_link](outputs.tf#L88) | Self link of the primary instance. |  |
| [self_links](outputs.tf#L93) | Self links of all instances. |  |
| [user_passwords](outputs.tf#L101) | Map of containing the password of all users created through terraform. | ✓ |
<!-- END TFDOC -->
