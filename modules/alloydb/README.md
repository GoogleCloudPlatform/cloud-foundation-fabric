# AlloyDB module

This module manages the creation of an AlloyDB cluster. It also supports cross-region replication scenario by setting up a secondary cluster.
It can also create an initial set of users via the `users` variable.

Note that this module assumes that some options are the same for both the primary instance and the secondary one in case of cross regional replication configuration.

> [!WARNING]
> If you use the `users` field, you terraform state will contain each user's password in plain text.

<!-- TOC -->
* [AlloyDB module](#alloydb-module)
  * [Examples](#examples)
    * [Simple example](#simple-example)
    * [Cross region replication](#cross-region-replication)
    * [PSC instance](#psc-instance)
    * [Custom flags and users definition](#custom-flags-and-users-definition)
    * [CMEK encryption](#cmek-encryption)
  * [Variables](#variables)
  * [Outputs](#outputs)
  * [Fixtures](#fixtures)
<!-- TOC -->

## Examples
### Simple example

This example shows how to setup a project, VPC and AlloyDB cluster and instance.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  parent          = var.folder_id
  name            = "alloydb"
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
    ranges = { alloydb = "10.60.0.0/16" }
  }]
  subnets_psc = [{
    ip_cidr_range = "10.0.3.0/24"
    name          = "psc"
    region        = var.region
  }]
}

module "alloydb" {
  source       = "./fabric/modules/alloydb"
  project_id   = module.project.project_id
  cluster_name = "db"
  network_config = {
    psa_config = {
      network = module.vpc.id
    }
  }
  instance_name = "db"
  location      = var.region
}
# tftest modules=3 resources=16 inventory=simple.yaml e2e
```

### Cross region replication

```hcl
module "alloydb" {
  source        = "./fabric/modules/alloydb"
  project_id    = var.project_id
  cluster_name  = "db"
  location      = var.region
  instance_name = "db"
  network_config = {
    psa_config = {
      network = var.vpc.id
    }
  }
  cross_region_replication = {
    enabled = true
    region  = "europe-west12"
  }
}
# tftest modules=1 resources=4 inventory=cross_region_replication.yaml e2e
```

In a cross-region replication scenario (like in the previous example) this module also supports [promoting the secondary instance](https://cloud.google.com/alloydb/docs/cross-region-replication/work-with-cross-region-replication#promote-secondary-cluster) to become a primary instance via the `var.cross_region_replication.promote_secondary` flag.


### PSC instance

```hcl
module "alloydb" {
  source        = "./fabric/modules/alloydb"
  project_id    = var.project_id
  cluster_name  = "db"
  location      = var.region
  instance_name = "db"
  network_config = {
    psc_config = { allowed_consumer_projects = [var.project_number] }
  }
}
# tftest modules=1 resources=2 inventory=psc.yaml e2e
```

### Custom flags and users definition

```hcl
module "alloydb" {
  source        = "./fabric/modules/alloydb"
  project_id    = var.project_id
  cluster_name  = "primary"
  location      = var.region
  instance_name = "primary"
  flags = {
    "alloydb.enable_pgaudit"            = "on"
    "alloydb.iam_authentication"        = "on"
    idle_in_transaction_session_timeout = "900000"
    timezone                            = "'UTC'"
  }
  network_config = {
    psa_config = {
      network = var.vpc.id
    }
  }
  users = {
    # generate a password for user1
    user1 = {
      password = null
    }
    # assign a password to user2
    user2 = {
      password = "mypassword"
    }
  }
}
# tftest modules=1 resources=5 inventory=custom.yaml e2e
```

### CMEK encryption

```hcl
module "project" {
  source          = "./fabric/modules/project"
  name            = "alloycmek"
  billing_account = var.billing_account_id
  prefix          = var.prefix
  parent          = var.folder_id
  services = [
    "alloydb.googleapis.com",
    "cloudkms.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

module "kms" {
  source     = "./fabric/modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = var.region
    name     = "keyring"
  }
  keys = {
    "key-regional" = {
    }
  }
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      module.project.service_agents.alloydb.iam_email
    ]
  }
}

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = module.project.project_id
  name       = "my-network"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "production"
      region        = var.region
    },
  ]
  psa_configs = [{
    ranges = { myrange = "10.0.1.0/24" }
  }]
}


module "alloydb" {
  source        = "./fabric/modules/alloydb"
  project_id    = module.project.project_id
  cluster_name  = "primary"
  location      = var.region
  instance_name = "primary"
  network_config = {
    psa_config = {
      network = module.vpc.id
    }
  }
  encryption_config = {
    primary_kms_key_name = module.kms.keys.key-regional.id
  }
}

# tftest inventory=cmek.yaml e2e
```

## Tag bindings

Refer to the [Creating and managing tags](https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing) documentation for details on usage.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  tags = {
    environment = {
      description = "Environment specification."
      values = {
        dev     = {}
        prod    = {}
        sandbox = {}
      }
    }
  }
}

module "alloydb" {
  source        = "./fabric/modules/alloydb"
  project_id    = var.project_id
  cluster_name  = "primary"
  location      = var.region
  instance_name = "primary"
  network_config = {
    psa_config = {
      network = var.vpc.id
    }
  }
  tag_bindings = {
    env-sandbox = module.org.tag_values["environment/sandbox"].id
  }
}
# tftest modules=2 resources=7
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cluster_name](variables.tf#L99) | Name of the primary cluster. | <code>string</code> | ✓ |  |
| [instance_name](variables.tf#L184) | Name of primary instance. | <code>string</code> | ✓ |  |
| [location](variables.tf#L195) | Region or zone of the cluster and instance. | <code>string</code> | ✓ |  |
| [network_config](variables.tf#L251) | Network configuration for cluster and instance. Only one between psa_config and psc_config can be used. | <code title="object&#40;&#123;&#10;  psa_config &#61; optional&#40;object&#40;&#123;&#10;    network                      &#61; optional&#40;string&#41;&#10;    allocated_ip_range           &#61; optional&#40;string&#41;&#10;    authorized_external_networks &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    enable_public_ip             &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  psc_config &#61; optional&#40;object&#40;&#123;&#10;    allowed_consumer_projects &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L294) | The ID of the project where this instances will be created. | <code>string</code> | ✓ |  |
| [annotations](variables.tf#L17) | Map FLAG_NAME=>VALUE for annotations which allow client tools to store small amount of arbitrary data. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [automated_backup_configuration](variables.tf#L23) | Automated backup settings for cluster. | <code title="object&#40;&#123;&#10;  enabled       &#61; optional&#40;bool, false&#41;&#10;  backup_window &#61; optional&#40;string, &#34;1800s&#34;&#41;&#10;  location      &#61; optional&#40;string&#41;&#10;  weekly_schedule &#61; optional&#40;object&#40;&#123;&#10;    days_of_week &#61; optional&#40;list&#40;string&#41;, &#91;&#10;      &#34;MONDAY&#34;, &#34;TUESDAY&#34;, &#34;WEDNESDAY&#34;, &#34;THURSDAY&#34;, &#34;FRIDAY&#34;, &#34;SATURDAY&#34;, &#34;SUNDAY&#34;&#10;    &#93;&#41;&#10;    start_times &#61; optional&#40;object&#40;&#123;&#10;      hours   &#61; optional&#40;number, 23&#41;&#10;      minutes &#61; optional&#40;number, 0&#41;&#10;      seconds &#61; optional&#40;number, 0&#41;&#10;      nanos   &#61; optional&#40;number, 0&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  retention_count  &#61; optional&#40;number, 7&#41;&#10;  retention_period &#61; optional&#40;string, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled       &#61; false&#10;  backup_window &#61; &#34;1800s&#34;&#10;  location      &#61; null&#10;  weekly_schedule &#61; &#123;&#10;    days_of_week &#61; &#91;&#34;MONDAY&#34;, &#34;TUESDAY&#34;, &#34;WEDNESDAY&#34;, &#34;THURSDAY&#34;, &#34;FRIDAY&#34;, &#34;SATURDAY&#34;, &#34;SUNDAY&#34;&#93;&#10;    start_times &#61; &#123;&#10;      hours   &#61; 23&#10;      minutes &#61; 0&#10;      seconds &#61; 0&#10;      nanos   &#61; 0&#10;    &#125;&#10;  &#125;&#10;  retention_count  &#61; 7&#10;  retention_period &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [availability_type](variables.tf#L76) | Availability type for the primary replica. Either `ZONAL` or `REGIONAL`. | <code>string</code> |  | <code>&#34;REGIONAL&#34;</code> |
| [client_connection_config](variables.tf#L82) | Client connection config. | <code title="object&#40;&#123;&#10;  require_connectors &#61; optional&#40;bool, false&#41;&#10;  ssl_config &#61; optional&#40;object&#40;&#123;&#10;    ssl_mode &#61; string&#10;  &#125;&#41;, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [cluster_display_name](variables.tf#L93) | Display name of the primary cluster. | <code>string</code> |  | <code>null</code> |
| [continuous_backup_configuration](variables.tf#L104) | Continuous backup settings for cluster. | <code title="object&#40;&#123;&#10;  enabled              &#61; optional&#40;bool, false&#41;&#10;  recovery_window_days &#61; optional&#40;number, 14&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled              &#61; true&#10;  recovery_window_days &#61; 14&#10;&#125;">&#123;&#8230;&#125;</code> |
| [cross_region_replication](variables.tf#L117) | Cross region replication config. | <code title="object&#40;&#123;&#10;  enabled                         &#61; optional&#40;bool, false&#41;&#10;  promote_secondary               &#61; optional&#40;bool, false&#41;&#10;  region                          &#61; optional&#40;string, null&#41;&#10;  secondary_cluster_display_name  &#61; optional&#40;string, null&#41;&#10;  secondary_cluster_name          &#61; optional&#40;string, null&#41;&#10;  secondary_instance_display_name &#61; optional&#40;string, null&#41;&#10;  secondary_instance_name         &#61; optional&#40;string, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [database_version](variables.tf#L135) | Database type and version to create. | <code>string</code> |  | <code>&#34;POSTGRES_15&#34;</code> |
| [deletion_policy](variables.tf#L141) | AlloyDB cluster and instance deletion policy. | <code>string</code> |  | <code>null</code> |
| [display_name](variables.tf#L147) | AlloyDB instance display name. | <code>string</code> |  | <code>null</code> |
| [encryption_config](variables.tf#L153) | Set encryption configuration. KMS name format: 'projects/[PROJECT]/locations/[REGION]/keyRings/[RING]/cryptoKeys/[KEY_NAME]'. | <code title="object&#40;&#123;&#10;  primary_kms_key_name   &#61; string&#10;  secondary_kms_key_name &#61; optional&#40;string, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [flags](variables.tf#L163) | Map FLAG_NAME=>VALUE for database-specific tuning. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [gce_zone](variables.tf#L169) | The GCE zone that the instance should serve from. This can ONLY be specified for ZONAL instances. If present for a REGIONAL instance, an error will be thrown. | <code>string</code> |  | <code>null</code> |
| [initial_user](variables.tf#L175) | AlloyDB cluster initial user credentials. | <code title="object&#40;&#123;&#10;  user     &#61; optional&#40;string, &#34;root&#34;&#41;&#10;  password &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [labels](variables.tf#L189) | Labels to be attached to all instances. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [machine_config](variables.tf#L200) | AlloyDB machine config. | <code title="object&#40;&#123;&#10;  cpu_count &#61; optional&#40;number, 2&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  cpu_count &#61; 2&#10;&#125;">&#123;&#8230;&#125;</code> |
| [maintenance_config](variables.tf#L211) | Set maintenance window configuration. | <code title="object&#40;&#123;&#10;  enabled &#61; optional&#40;bool, false&#41;&#10;  day     &#61; optional&#40;string, &#34;SUNDAY&#34;&#41;&#10;  start_time &#61; optional&#40;object&#40;&#123;&#10;    hours   &#61; optional&#40;number, 23&#41;&#10;    minutes &#61; optional&#40;number, 0&#41;&#10;    seconds &#61; optional&#40;number, 0&#41;&#10;    nanos   &#61; optional&#40;number, 0&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled &#61; false&#10;  day     &#61; &#34;SUNDAY&#34;&#10;  start_time &#61; &#123;&#10;    hours   &#61; 23&#10;    minutes &#61; 0&#10;    seconds &#61; 0&#10;    nanos   &#61; 0&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [prefix](variables.tf#L284) | Optional prefix used to generate instance names. | <code>string</code> |  | <code>null</code> |
| [query_insights_config](variables.tf#L299) | Query insights config. | <code title="object&#40;&#123;&#10;  query_string_length     &#61; optional&#40;number, 1024&#41;&#10;  record_application_tags &#61; optional&#40;bool, true&#41;&#10;  record_client_address   &#61; optional&#40;bool, true&#41;&#10;  query_plans_per_minute  &#61; optional&#40;number, 5&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  query_string_length     &#61; 1024&#10;  record_application_tags &#61; true&#10;  record_client_address   &#61; true&#10;  query_plans_per_minute  &#61; 5&#10;&#125;">&#123;&#8230;&#125;</code> |
| [tag_bindings](variables.tf#L315) | Tag bindings for this service, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [users](variables.tf#L322) | Map of users to create in the primary instance (and replicated to other replicas). Set PASSWORD to null if you want to get an autogenerated password. The user types available are: 'ALLOYDB_BUILT_IN' or 'ALLOYDB_IAM_USER'. | <code title="map&#40;object&#40;&#123;&#10;  password &#61; optional&#40;string&#41;&#10;  roles    &#61; optional&#40;list&#40;string&#41;, &#91;&#34;alloydbsuperuser&#34;&#93;&#41;&#10;  type     &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L24) | Fully qualified primary instance id. |  |
| [ids](outputs.tf#L29) | Fully qualified ids of all instances. |  |
| [instances](outputs.tf#L37) | AlloyDB instance resources. | ✓ |
| [ip](outputs.tf#L43) | IP address of the primary instance. |  |
| [ips](outputs.tf#L48) | IP addresses of all instances. |  |
| [name](outputs.tf#L55) | Name of the primary instance. |  |
| [names](outputs.tf#L60) | Names of all instances. |  |
| [psc_dns_name](outputs.tf#L68) | AlloyDB Primary instance PSC DNS name. |  |
| [psc_dns_names](outputs.tf#L73) | AlloyDB instances PSC DNS names. |  |
| [secondary_id](outputs.tf#L80) | Fully qualified primary instance id. |  |
| [secondary_ip](outputs.tf#L85) | IP address of the primary instance. |  |
| [service_attachment](outputs.tf#L90) | AlloyDB Primary instance service attachment. |  |
| [service_attachments](outputs.tf#L95) | AlloyDB instances service attachment. |  |
| [user_passwords](outputs.tf#L102) | Map of containing the password of all users created through terraform. | ✓ |
<!-- END TFDOC -->
