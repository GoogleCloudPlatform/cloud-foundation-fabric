# Google Cloud Composer
This module Manages a Google Cloud [Composer](https://cloud.google.com/composer) environment.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Simple](#simple)
  - [Node confiugration](#node-confiugration)
  - [Private environment confiugration](#private-environment-confiugration)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

### Simple
```hcl
module "composer-environment" {
  source     = "./fabric/modules/cloud-composer"
  project_id = "my-project"
  name       = "my-env"
  region     = "europe-west1"
}
# tftest modules=1 resources=1
```
### Node confiugration
It is possible to configure nodes using the variable [node_config](variables.tf#L36).
```hcl
module "composer-environment" {
  source     = "./fabric/modules/cloud-composer"
  project_id = "my-project"
  name       = "my-env"
  region     = "europe-west1"
  node_config = {
    zone            = "europe-west1"
    machine_type    = "n2-standard-4"
    network         = ""
    subnetwork      = "projects/PROJECT/regions/europe-west1/subnetworks/SUBNET"
    disk_size_gb    = 50
    ip_allocation_policy = [{
      use_ip_aliases = true
      cluster_secondary_range_name  = "composer-pod"
      services_secondary_range_name = "composer-services"
    }]
  }
}
# tftest modules=1 resources=1
```

### Private environment confiugration
To set private environment configuration set [private_environment_config](variables.tf#L85)`.enable_private_endpoint` at `true`, configure the master, sql and web server cidr blocks.
```hcl
module "composer-environment" {
  source     = "./fabric/modules/cloud-composer"
  project_id = "my-project"
  name       = "my-env"
  region     = "europe-west1"
  private_environment_config = {
    enable_private_endpoint    = true
    master_ipv4_cidr_block     = "10.10.10.0/28"
    cloud_sql_ipv4_cidr_block  = "10.10.11.0/24"
    web_server_ipv4_cidr_block = "10.10.12.0/28"
  }
}
# tftest modules=1 resources=1
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [database_config](variables.tf#L121) | The configuration settings for Cloud SQL instance used internally by Apache Airflow software. For Cloud Composer 1 only. | <code title="object&#40;&#123;&#10;  machine_type &#61; string&#10;&#125;&#41;&#10;&#10;&#10;default &#61; null">object&#40;&#123;&#8230;default &#61; null</code> | ✓ |  |
| [name](variables.tf#L22) | Name of the environment. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L27) | The ID of the project in which the resource belongs. | <code>string</code> | ✓ |  |
| [region](variables.tf#L17) | The location or Compute Engine region for the environment. | <code>string</code> | ✓ |  |
| [allowed_ip_range](variables.tf#L112) | The network-level access control policy for the Airflow web server. If unspecified, no network-level access restrictions are applied. For Cloud Composer 1 only. | <code title="object&#40;&#123;&#10;  value       &#61; string&#10;  description &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [encryption_config](variables.tf#L139) | The encryption options for the Cloud Composer environment and its dependencies. | <code title="object&#40;&#123;&#10;  kms_key_name &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [environment_size](variables.tf#L38) | The environment size controls the performance parameters of the managed Cloud Composer infrastructure that includes the Airflow database. Values for environment size are ENVIRONMENT_SIZE_SMALL, ENVIRONMENT_SIZE_MEDIUM, and ENVIRONMENT_SIZE_LARGE. | <code>string</code> |  | <code>&#34;ENVIRONMENT_SIZE_SMALL&#34;</code> |
| [maintenance_window](variables.tf#L147) | The configuration settings for Cloud Composer maintenance windows. BETA FOR Cloud Composer 1. | <code title="object&#40;&#123;&#10;  start_time &#61; string&#10;  end_time   &#61; string&#10;  recurrence &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [master_authorized_networks_config](variables.tf#L158) | Configuration options for the master authorized networks feature. Enabled master authorized networks will disallow all external traffic to access Kubernetes master through HTTPS except traffic from the given CIDR blocks, Google Compute Engine Public IPs and Google Prod IPs. | <code title="object&#40;&#123;&#10;  display_name &#61; bool&#10;  cidr_blocks &#61; object&#40;&#123;&#10;    display_name &#61; optional&#40;string&#41;&#10;    cidr_block   &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [node_config](variables.tf#L50) | The configuration used for the Kubernetes Engine cluster. | <code title="object&#40;&#123;&#10;  zone            &#61; optional&#40;string&#41;&#10;  machine_type    &#61; optional&#40;string&#41;&#10;  network         &#61; optional&#40;string&#41;&#10;  subnetwork      &#61; optional&#40;string&#41;&#10;  disk_size_gb    &#61; optional&#40;number&#41;&#10;  oauth_scopes    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  service_account &#61; optional&#40;string&#41;&#10;  tags            &#61; optional&#40;list&#40;string&#41;&#41;&#10;  ip_allocation_policy &#61; optional&#40;list&#40;object&#40;&#123;&#10;    use_ip_aliases                &#61; bool&#10;    cluster_secondary_range_name  &#61; optional&#40;string&#41;&#10;    services_secondary_range_name &#61; optional&#40;string&#41;&#10;    cluster_ipv4_cidr_block       &#61; optional&#40;string&#41;&#10;    services_ipv4_cidr_block      &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  enable_ip_masq_agent &#61; optional&#40;bool&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [node_count](variables.tf#L32) | The number of nodes in the Kubernetes Engine cluster of the environment. For Cloud Composer 1 only. | <code>number</code> |  | <code>3</code> |
| [private_environment_config](variables.tf#L99) |  | <code title="object&#40;&#123;&#10;  connection_type                  &#61; optional&#40;string&#41;&#10;  enable_private_endpoint          &#61; optional&#40;bool&#41;&#10;  master_ipv4_cidr_block           &#61; optional&#40;string&#41;&#10;  cloud_sql_ipv4_cidr_block        &#61; optional&#40;string&#41;&#10;  web_server_ipv4_cidr_block       &#61; optional&#40;string&#41;&#10;  enable_privately_used_public_ips &#61; optional&#40;bool&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [recovery_config](variables.tf#L73) | The configuration settings for recovery, for Cloud Composer 2 only. | <code title="object&#40;&#123;&#10;  scheduled_snapshots_config &#61; object&#40;&#123;&#10;    enabled                    &#61; bool&#10;    snapshot_location          &#61; optional&#40;string&#41;&#10;    snapshot_creation_schedule &#61; optional&#40;string&#41;&#10;    time_zone                  &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [resilience_mode](variables.tf#L44) | The resilience mode states whether high resilience is enabled for the environment or not. Values for resilience mode are HIGH_RESILIENCE for high resilience and STANDARD_RESILIENCE for standard resilience. For Cloud Composer 2.1.15 or newer only. | <code>string</code> |  | <code>null</code> |
| [software_config](variables.tf#L86) | The configuration settings for software inside the environment. | <code title="object&#40;&#123;&#10;  airflow_config_overrides &#61; optional&#40;map&#40;string&#41;&#41;&#10;  pypi_packages            &#61; optional&#40;map&#40;string&#41;&#41;&#10;  env_variables            &#61; optional&#40;map&#40;string&#41;&#41;&#10;  image_version            &#61; optional&#40;string&#41;&#10;  python_version           &#61; optional&#40;string&#41;&#10;  scheduler_count          &#61; optional&#40;number&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [web_server_config](variables.tf#L131) | The configuration settings for the Airflow web server App Engine instance. For Cloud Composer 1 only. | <code title="object&#40;&#123;&#10;  machine_type &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [workloads_config](variables.tf#L170) | The Kubernetes workloads configuration for GKE cluster associated with the Cloud Composer environment. For Cloud Composer 2 only. | <code title="object&#40;&#123;&#10;  scheduler &#61; optional&#40;object&#40;&#123;&#10;    cpu        &#61; optional&#40;number&#41;&#10;    count      &#61; optional&#40;number&#41;&#10;    memory_gb  &#61; optional&#40;number&#41;&#10;    storage_gb &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  triggerer &#61; optional&#40;object&#40;&#123;&#10;    cpu       &#61; optional&#40;number&#41;&#10;    count     &#61; optional&#40;number&#41;&#10;    memory_gb &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  web_server &#61; optional&#40;object&#40;&#123;&#10;    cpu        &#61; optional&#40;number&#41;&#10;    storage_gb &#61; optional&#40;number&#41;&#10;    memory_gb  &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  worker &#61; optional&#40;object&#40;&#123;&#10;    cpu        &#61; optional&#40;number&#41;&#10;    storage_gb &#61; optional&#40;number&#41;&#10;    memory_gb  &#61; optional&#40;number&#41;&#10;    min_count  &#61; optional&#40;number&#41;&#10;    max_count  &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [composer-gke-cluster](outputs.tf#L22) | The Kubernetes Engine cluster used to run this environment. |  |
| [composer-id](outputs.tf#L17) | An identifier for the resource with format projects/{{project}}/locations/{{region}}/environments/{{name}}. |  |
<!-- END TFDOC -->
