# Cloud SQL instance with read replicas

This module manages the creation of Cloud SQL instances with potential read replicas in other regions. It can also create an initial set of users and databases via the `users` and `databases` parameters.

Note that this module assumes that some options are the same for both the primary instance and all the replicas (e.g. tier, disks, labels, flags, etc).

*Warning:* if you use the `users` field, you terraform state will contain each user's password in plain text.

## Simple example

This example shows how to setup a project, VPC and a standalone Cloud SQL instance.

```hcl
module "project" {
  source          = "./modules/project"
  billing_account = var.billing_account_id
  parent          = var.organization_id
  name            = "my-db-project"
  services = [
    "servicenetworking.googleapis.com"
  ]
}

module "vpc" {
  source     = "./modules/net-vpc"
  project_id = module.project.project_id
  name       = "my-network"
  private_service_networking_range = "10.60.0.0/16"
}

module "db" {
  source           = "./modules/cloudsql-instance"
  project_id       = module.project.project_id
  network          = module.vpc.self_link
  name             = "db"
  region           = "europe-west1"
  database_version = "POSTGRES_13"
  tier             = "db-g1-small"
}
# tftest:modules=3:resources=6
```

## Cross-regional read replica

```hcl
module "db" {
  source           = "./modules/cloudsql-instance"
  project_id       = var.project_id
  network          = var.vpc.self_link
  name             = "db"
  region           = "europe-west1"
  database_version = "POSTGRES_13"
  tier             = "db-g1-small"

  replicas = {
    replica1 = "europe-west3"
    replica2 = "us-central1"
  }
}
# tftest:modules=1:resources=3
```

## Custom flags, databases and users

```hcl
module "db" {
  source           = "./modules/cloudsql-instance"
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
    user2  = "mypassword"
  }
}
# tftest:modules=1:resources=6
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| database_version | Database type and version to create. | <code title="">string</code> | ✓ |  |
| name | Name of primary replica. | <code title="">string</code> | ✓ |  |
| network | VPC self link where the instances will be deployed. Private Service Networking must be enabled and configured in this VPC. | <code title="">string</code> | ✓ |  |
| project_id | The ID of the project where this instances will be created. | <code title="">string</code> | ✓ |  |
| region | Region of the primary replica. | <code title="">string</code> | ✓ |  |
| tier | The machine type to use for the instances. | <code title="">string</code> | ✓ |  |
| *authorized_networks* | Map of NAME=>CIDR_RANGE to allow to connect to the database(s). | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">null</code> |
| *availability_type* | Availability type for the primary replica. Either `ZONAL` or `REGIONAL` | <code title="">string</code> |  | <code title="">ZONAL</code> |
| *backup_configuration* | Backup settings for primary instance. Will be automatically enabled if using MySQL with one or more replicas | <code title="object&#40;&#123;&#10;enabled            &#61; bool&#10;binary_log_enabled &#61; bool&#10;start_time         &#61; string&#10;location           &#61; string&#10;log_retention_days &#61; number&#10;retained_count     &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;enabled            &#61; false&#10;binary_log_enabled &#61; false&#10;start_time         &#61; &#34;23:00&#34;&#10;location           &#61; &#34;EU&#34;&#10;log_retention_days &#61; 7&#10;retention_count    &#61; 7&#10;&#125;">...</code> |
| *databases* | Databases to create once the primary instance is created. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">null</code> |
| *deletion_protection* | Allow terraform to delete instances. | <code title="">bool</code> |  | <code title="">false</code> |
| *disk_size* | Disk size in GB. Set to null to enable autoresize. | <code title="">number</code> |  | <code title="">null</code> |
| *disk_type* | The type of data disk: `PD_SSD` or `PD_HDD`. | <code title="">string</code> |  | <code title="">PD_SSD</code> |
| *flags* | Map FLAG_NAME=>VALUE for database-specific tuning. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">null</code> |
| *labels* | Labels to be attached to all instances. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">null</code> |
| *prefix* | Prefix used to generate instance names. | <code title="">string</code> |  | <code title="">null</code> |
| *replicas* | Map of NAME=>REGION for additional read replicas. Set to null to disable replica creation. | <code title="map&#40;any&#41;">map(any)</code> |  | <code title="">null</code> |
| *users* | Map of users to create in the primary instance (and replicated to other replicas) in the format USER=>PASSWORD. For MySQL, anything afterr the first `@` (if persent) will be used as the user's host. Set PASSWORD to null if you want to get an autogenerated password | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| connection_name | Connection name of the primary instance |  |
| connection_names | Connection names of all instances |  |
| id | ID of the primary instance |  |
| ids | IDs of all instances |  |
| instances | Cloud SQL instance resources | ✓ |
| ip | IP address of the primary instance |  |
| ips | IP addresses of all instances |  |
| self_link | Self link of the primary instance |  |
| self_links | Self links of all instances |  |
| user_passwords | Map of containing the password of all users created through terraform. | ✓ |
<!-- END TFDOC -->
