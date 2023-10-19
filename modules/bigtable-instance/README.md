# Google Cloud BigTable Module

This module allows managing a single BigTable instance, including access configuration and tables.

## TODO

- [ ] support bigtable_app_profile
- [ ] support IAM for tables

## Examples

### Instance with access configuration

```hcl

module "bigtable-instance" {
  source     = "./fabric/modules/bigtable-instance"
  project_id = "my-project"
  name       = "instance"
  clusters = {
    my-cluster = {
      zone = "europe-west1-b"
    }
  }
  tables = {
    test1 = {},
    test2 = {
      split_keys = ["a", "b", "c"]
    }
  }
  iam = {
    "roles/bigtable.user" = ["user:viewer@testdomain.com"]
  }
}
# tftest modules=1 resources=4 inventory=simple.yaml
```

### Instance with tables and column families

```hcl

module "bigtable-instance" {
  source     = "./fabric/modules/bigtable-instance"
  project_id = "my-project"
  name       = "instance"
  clusters = {
    my-cluster = {
      zone = "europe-west1-b"
    }
  }
  tables = {
    test1 = {},
    test2 = {
      split_keys = ["a", "b", "c"]
      column_families = {
        cf1 = {}
        cf2 = {}
        cf3 = {}
      }
    }
    test3 = {
      column_families = {
        cf1 = {}
      }
    }
  }
}
# tftest modules=1 resources=4 inventory=columns.yaml
```

### Instance with replication enabled

```hcl

module "bigtable-instance" {
  source     = "./fabric/modules/bigtable-instance"
  project_id = "my-project"
  name       = "instance"
  clusters = {
    first-cluster = {
      zone = "europe-west1-b"
    }
    second-cluster = {
      zone = "europe-southwest1-a"
    }
    third-cluster = {
      zone = "us-central1-b"
    }
  }
}
# tftest modules=1 resources=1 inventory=replication.yaml
```

### Instance with garbage collection policy

```hcl

module "bigtable-instance" {
  source     = "./fabric/modules/bigtable-instance"
  project_id = "my-project"
  name       = "instance"
  clusters = {
    my-cluster = {
      zone = "europe-west1-b"
    }
  }
  tables = {
    test1 = {
      column_families = {
        cf1 = {
          gc_policy = {
            deletion_policy = "ABANDON"
            max_age         = "18h"
          }
        }
        cf2 = {}
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=gc.yaml
```

### Instance with default garbage collection policy

The default garbage collection policy is applied to any column family that does
not specify a `gc_policy`. If a column family specifies a `gc_policy`, the
default garbage collection policy is ignored for that column family.

```hcl

module "bigtable-instance" {
  source     = "./fabric/modules/bigtable-instance"
  project_id = "my-project"
  name       = "instance"
  clusters = {
    my-cluster = {
      zone = "europe-west1-b"
    }
  }
  default_gc_policy = {
    deletion_policy = "ABANDON"
    max_age         = "18h"
    max_version     = 7
  }
  tables = {
    test1 = {
      column_families = {
        cf1 = {}
        cf2 = {}
      }
    }
  }
}
# tftest modules=1 resources=4
```

### Instance with static number of nodes

If you are not using autoscaling settings, you must set a specific number of nodes with the variable `num_nodes`.

```hcl

module "bigtable-instance" {
  source     = "./fabric/modules/bigtable-instance"
  project_id = "my-project"
  name       = "instance"
  clusters = {
    my-cluster = {
      zone      = "europe-west1-b"
      num_nodes = 5
    }
  }
}
# tftest modules=1 resources=1 inventory=static.yaml
```

### Instance with autoscaling (based on CPU only)

If you use autoscaling, you should not set the variable `num_nodes`.

```hcl

module "bigtable-instance" {
  source     = "./fabric/modules/bigtable-instance"
  project_id = "my-project"
  name       = "instance"
  clusters = {
    my-cluster = {
      zone = "europe-southwest1-b"
      autoscaling = {
        min_nodes  = 3
        max_nodes  = 7
        cpu_target = 70
      }
    }
  }


}
# tftest modules=1 resources=1 inventory=autoscaling1.yaml
```

### Instance with autoscaling (based on CPU and/or storage)

```hcl

module "bigtable-instance" {
  source     = "./fabric/modules/bigtable-instance"
  project_id = "my-project"
  name       = "instance"
  clusters = {
    my-cluster = {
      zone         = "europe-southwest1-a"
      storage_type = "SSD"
      autoscaling = {
        min_nodes      = 3
        max_nodes      = 7
        cpu_target     = 70
        storage_target = 4096
      }
    }
  }
}
# tftest modules=1 resources=1 inventory=autoscaling2.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [clusters](variables.tf#L17) | Clusters to be created in the BigTable instance. Set more than one cluster to enable replication. If you set autoscaling, num_nodes will be ignored. | <code title="map&#40;object&#40;&#123;&#10;  zone         &#61; optional&#40;string&#41;&#10;  storage_type &#61; optional&#40;string&#41;&#10;  num_nodes    &#61; optional&#40;number&#41;&#10;  autoscaling &#61; optional&#40;object&#40;&#123;&#10;    min_nodes      &#61; number&#10;    max_nodes      &#61; number&#10;    cpu_target     &#61; number&#10;    storage_target &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [name](variables.tf#L81) | The name of the Cloud Bigtable instance. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L86) | Id of the project where datasets will be created. | <code>string</code> | ✓ |  |
| [default_autoscaling](variables.tf#L33) | Default settings for autoscaling of clusters. This will be the default autoscaling for any cluster not specifying any autoscaling details. | <code title="object&#40;&#123;&#10;  min_nodes      &#61; number&#10;  max_nodes      &#61; number&#10;  cpu_target     &#61; number&#10;  storage_target &#61; optional&#40;number&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [default_gc_policy](variables.tf#L44) | Default garbage collection policy, to be applied to all column families and all tables. Can be override in the tables variable for specific column families. | <code title="object&#40;&#123;&#10;  deletion_policy &#61; optional&#40;string&#41;&#10;  gc_rules        &#61; optional&#40;string&#41;&#10;  mode            &#61; optional&#40;string&#41;&#10;  max_age         &#61; optional&#40;string&#41;&#10;  max_version     &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [deletion_protection](variables.tf#L56) | Whether or not to allow Terraform to destroy the instance. Unless this field is set to false in Terraform state, a terraform destroy or terraform apply that would delete the instance will fail. | <code>bool</code> |  | <code>true</code> |
| [display_name](variables.tf#L63) | The human-readable display name of the Bigtable instance. | <code>string</code> |  | <code>null</code> |
| [iam](variables.tf#L69) | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [instance_type](variables.tf#L75) | (deprecated) The instance type to create. One of 'DEVELOPMENT' or 'PRODUCTION'. | <code>string</code> |  | <code>null</code> |
| [tables](variables.tf#L91) | Tables to be created in the BigTable instance. | <code title="map&#40;object&#40;&#123;&#10;  split_keys &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  column_families &#61; optional&#40;map&#40;object&#40;&#10;    &#123;&#10;      gc_policy &#61; optional&#40;object&#40;&#123;&#10;        deletion_policy &#61; optional&#40;string&#41;&#10;        gc_rules        &#61; optional&#40;string&#41;&#10;        mode            &#61; optional&#40;string&#41;&#10;        max_age         &#61; optional&#40;string&#41;&#10;        max_version     &#61; optional&#40;string&#41;&#10;      &#125;&#41;, null&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified instance id. |  |
| [instance](outputs.tf#L26) | BigTable instance. |  |
| [table_ids](outputs.tf#L35) | Map of fully qualified table ids keyed by table name. |  |
| [tables](outputs.tf#L40) | Table resources. |  |
<!-- END TFDOC -->
