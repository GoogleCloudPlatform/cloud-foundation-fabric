# AlloyDB cluster and instance with read replicas

This module manages the creation of AlloyDB cluster and configuration with/without automated backup policy, Primary node instance and Read Node Pools. 


## Simple example

This example shows how to create Alloydb cluster and instance with multiple read pools in GCP project.

```hcl
module "alloydb" {
  source       = "./fabric/modules/alloydb-instance"
  project_id   = "myproject"
  cluster_id   = "alloydb-cluster-all"
  location     = "europe-west2"
  labels       = {}
  display_name = ""
  initial_user = {
    user     = "alloydb-cluster-full",
    password = "alloydb-cluster-password"
  }
  network_self_link = "projects/myproject/global/networks/default"

  automated_backup_policy = null

  primary_instance_config = {
    instance_id       = "primary-instance-1",
    instance_type     = "PRIMARY",
    machine_cpu_count = 2,
    database_flags    = {},
    display_name      = "alloydb-primary-instance"
  }
  read_pool_instance = [
    {
      instance_id       = "read-instance-1",
      display_name      = "read-instance-1",
      instance_type     = "READ_POOL",
      node_count        = 1,
      database_flags    = {},
      machine_cpu_count = 1
    },
    {
      instance_id       = "read-instance-2",
      display_name      = "read-instance-2",
      instance_type     = "READ_POOL",
      node_count        = 1,
      database_flags    = {},
      machine_cpu_count = 1
    }
  ]

}

# tftest skip
```
## TODO
- [ ] Add IAM support
- [ ] support password in output
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cluster_id](variables.tf#L35) | The ID of the alloydb cluster. | <code>string</code> | ✓ |  |
| [network_self_link](variables.tf#L83) | Network ID where the AlloyDb cluster will be deployed. | <code>string</code> | ✓ |  |
| [primary_instance_config](variables.tf#L88) | Primary cluster configuration that supports read and write operations. | <code title="object&#40;&#123;&#10;  instance_id       &#61; string,&#10;  display_name      &#61; optional&#40;string&#41;,&#10;  database_flags    &#61; optional&#40;map&#40;string&#41;&#41;&#10;  labels            &#61; optional&#40;map&#40;string&#41;&#41;&#10;  annotations       &#61; optional&#40;map&#40;string&#41;&#41;&#10;  gce_zone          &#61; optional&#40;string&#41;&#10;  availability_type &#61; optional&#40;string&#41;&#10;  machine_cpu_count &#61; optional&#40;number, 2&#41;,&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L110) | The ID of the project in which to provision resources. | <code>string</code> | ✓ |  |
| [automated_backup_policy](variables.tf#L17) | The automated backup policy for this cluster. | <code title="object&#40;&#123;&#10;  location      &#61; optional&#40;string&#41;&#10;  backup_window &#61; optional&#40;string&#41;&#10;  enabled       &#61; optional&#40;bool&#41;&#10;  weekly_schedule &#61; optional&#40;object&#40;&#123;&#10;    days_of_week &#61; optional&#40;list&#40;string&#41;&#41;&#10;    start_times  &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;,&#10;  quantity_based_retention_count &#61; optional&#40;number&#41;&#10;  time_based_retention_count     &#61; optional&#40;string&#41;&#10;  labels                         &#61; optional&#40;map&#40;string&#41;&#41;&#10;  backup_encryption_key_name     &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [display_name](variables.tf#L44) | Human readable display name for the Alloy DB Cluster. | <code>string</code> |  | <code>null</code> |
| [encryption_key_name](variables.tf#L50) | The fully-qualified resource name of the KMS key for cluster encryption. | <code>string</code> |  | <code>null</code> |
| [initial_user](variables.tf#L56) | Alloy DB Cluster Initial User Credentials. | <code title="object&#40;&#123;&#10;  user     &#61; optional&#40;string&#41;,&#10;  password &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [labels](variables.tf#L65) | User-defined labels for the alloydb cluster. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [location](variables.tf#L71) | Location where AlloyDb cluster will be deployed. | <code>string</code> |  | <code>&#34;europe-west2&#34;</code> |
| [network_name](variables.tf#L77) | The network name of the project in which to provision resources. | <code>string</code> |  | <code>&#34;multiple-readpool&#34;</code> |
| [read_pool_instance](variables.tf#L115) | List of Read Pool Instances to be created. | <code title="list&#40;object&#40;&#123;&#10;  instance_id       &#61; string&#10;  display_name      &#61; string&#10;  node_count        &#61; optional&#40;number, 1&#41;&#10;  database_flags    &#61; optional&#40;map&#40;string&#41;&#41;&#10;  availability_type &#61; optional&#40;string&#41;&#10;  gce_zone          &#61; optional&#40;string&#41;&#10;  machine_cpu_count &#61; optional&#40;number, 2&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cluster](outputs.tf#L17) | Cluster created. | ✓ |
| [cluster_id](outputs.tf#L23) | ID of the Alloy DB Cluster created. |  |
| [primary_instance](outputs.tf#L28) | Primary instance created. |  |
| [primary_instance_id](outputs.tf#L33) | ID of the primary instance created. |  |
| [read_pool_instance_ids](outputs.tf#L38) | IDs of the read instances created. |  |

<!-- END TFDOC -->

