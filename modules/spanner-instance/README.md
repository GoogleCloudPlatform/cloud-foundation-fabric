# Spanner instance

This module allows to create a spanner instance with associated spanner instance config and databases in the instance. Additionally it allows creating instance IAM bindings and database IAM bindings.

## Examples

### Basic instance with a database

```hcl
module "spanner_instace" {
  source     = "./fabric/modules/spanner-instance"
  project_id = var.project_id
  instance = {
    name         = "my-instance"
    display_name = "Regional instance in us-central1"
    config = {
      name = "regional-us-central1"
    }
    num_nodes = 1
  }
  databases = {
    my-database = {

    }
  }
}
# tftest modules=1 resources=2 inventory=simple-instance-with-database.yaml
```

### Instance with autoscaling

```hcl
module "spanner_instance" {
  source     = "./fabric/modules/spanner-instance"
  project_id = var.project_id
  instance = {
    name         = "my-instance"
    display_name = "Regional instance"
    config = {
      name = "regional-us-central1"
    }
    autoscaling = {
      limits = {
        min_processing_units = 2000
        max_processing_units = 3000
      }
      targets = {
        high_priority_cpu_utilization_percent = 75
        storage_utilization_percent           = 90
      }
    }
    labels = {
      foo = "bar"
    }
  }
}
# tftest modules=1 resources=1 inventory=instance-with-autoscaling.yaml
```

### Instance with custom config

```hcl
module "spanner_instance" {
  source     = "./fabric/modules/spanner-instance"
  project_id = var.project_id
  instance = {
    name         = "my-instance"
    display_name = "Regional instance"
    config = {
      name = "custom-nam11-config"
      auto_create = {
        display_name = "Test Spanner Instance Config"
        base_config  = "name11"
        replicas = [
          {
            location                = "us-west1"
            type                    = "READ_ONLY"
            default_leader_location = false
          }
        ]
      }
    }
    num_nodes = 1
  }
}
# tftest modules=1 resources=2 inventory=instance-with-custom-config.yaml
```

### New database in existing instance

```hcl
module "spanner_instance" {
  source     = "./fabric/modules/spanner-instance"
  project_id = var.project_id
  instance = {
    name         = "my-instance"
  }
  instance_create = false
  databases = {
    my-database = {

    }
  }
}
# tftest skip
```

### IAM

```hcl
module "spanner_instance" {
  source     = "./fabric/modules/spanner-instance"
  project_id = var.project_id
  instance = {
    name         = "my-instance"
    display_name = "Regional instance"
    config = {
      name = "regional-us-central1"
    }
    num_nodes = 1
  }
  databases = {
    my-database = {
      version_retention_period = "1d"
      iam = {
        "roles/spanner.databaseReader" = [
          "group:group1@myorg.com"
        ]
      }
      iam_bindings = {
        "spanner-database-role-user" = {
          role = "roles/spanner.databaseRoleUser"
          members = [
            "group:group2@myorg.com"
          ]
          condition = {
            title       = "role-my_role"
            description = "Grant permissions on my_role"
            expression  = "(resource.type == \"spanner.googleapis.com/DatabaseRole\" && (resource.name.endsWith(\"/my_role\")))"
          }
        }
      }
      iam_bindings_additive = {
        "spanner-database-admin" = {
          role   = "roles/spanner.databaseAdmin"
          member = "group:group3@myorg.com"
          condition = {
            title       = "delegated-role-grants"
            description = "Delegated role grants."
            expression = format(
              "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
              join(",", formatlist("'%s'",
                [
                  "roles/storage.databaseReader",
                ]
              ))
            )
          }
        }
      }
    }
  }
}
# tftest modules=1 resources=5 inventory=iam.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [instance](variables.tf#L89) | Instance attributes. | <code title="object&#40;&#123;&#10;  autoscaling &#61; optional&#40;object&#40;&#123;&#10;    limits &#61; optional&#40;object&#40;&#123;&#10;      max_nodes            &#61; optional&#40;number&#41;&#10;      max_processing_units &#61; optional&#40;number&#41;&#10;      min_nodes            &#61; optional&#40;number&#41;&#10;      min_processing_units &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    targets &#61; optional&#40;object&#40;&#123;&#10;      high_priority_cpu_utilization_percent &#61; optional&#40;number&#41;&#10;      storage_utilization_percent           &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  config &#61; optional&#40;object&#40;&#123;&#10;    name &#61; string&#10;    auto_create &#61; optional&#40;object&#40;&#123;&#10;      base_config  &#61; optional&#40;string&#41;&#10;      display_name &#61; optional&#40;string&#41;&#10;      labels       &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;      replicas &#61; list&#40;object&#40;&#123;&#10;        location                &#61; string&#10;        type                    &#61; string&#10;        default_leader_location &#61; bool&#10;        &#125;&#10;      &#41;&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  display_name     &#61; optional&#40;string&#41;&#10;  labels           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  name             &#61; string&#10;  num_nodes        &#61; optional&#40;number&#41;&#10;  processing_units &#61; optional&#40;number&#41;&#10;  force_destroy    &#61; optional&#40;bool&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L134) | Project id. | <code>string</code> | ✓ |  |
| [databases](variables.tf#L17) | Databases. | <code title="map&#40;object&#40;&#123;&#10;  database_dialect       &#61; optional&#40;string&#41;&#10;  ddl                    &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  deletion_protection    &#61; optional&#40;bool&#41;&#10;  enable_drop_protection &#61; optional&#40;bool&#41;&#10;  iam                    &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  kms_key_name             &#61; optional&#40;string&#41;&#10;  version_retention_period &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L63) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L69) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L79) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [instance_create](variables.tf#L127) | Set to false to manage databases and IAM bindings in an existing instance. | <code>bool</code> |  | <code>true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [spanner_database_ids](outputs.tf#L17) | Spanner database ids. |  |
| [spanner_databases](outputs.tf#L22) | Spanner databases. |  |
| [spanner_instance](outputs.tf#L27) | Spanner instance. |  |
| [spanner_instance_config](outputs.tf#L32) | Spanner instance config. |  |
| [spanner_instance_config_id](outputs.tf#L37) | Spanner instance config id. |  |
| [spanner_instance_id](outputs.tf#L42) | Spanner instance id. |  |
<!-- END TFDOC -->
