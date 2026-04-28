# Workstation cluster

This module allows to create a workstation cluster with associated workstation configs and workstations. In addition to this it allows to set up IAM bindings for the workstation configs and the workstations.

<!-- BEGIN TOC -->
- [Simple example](#simple-example)
- [Private cluster](#private-cluster)
- [Custom image](#custom-image)
- [IAM](#iam)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Simple example

Simple example showing how to create a cluster with publicly accessible workstations using the default base image.

```hcl
module "workstation-cluster" {
  source     = "./fabric/modules/workstation-cluster"
  project_id = var.project_id
  id         = "my-workstation-cluster"
  location   = var.region
  network_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
  workstation_configs = {
    my-workstation-config = {
      workstations = {
        my-workstation = {
          labels = {
            team = "my-team"
          }
        }
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=simple.yaml
```

## Private cluster

Example showing how to create a cluster with a privately accessible workstation using the default base image.

```hcl
module "workstation-cluster" {
  source     = "./fabric/modules/workstation-cluster"
  project_id = var.project_id
  id         = "my-workstation-cluster"
  location   = var.region
  network_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
  private_cluster_config = {
    enable_private_endpoint = true
  }
  workstation_configs = {
    my-workstation-config = {
      gce_instance = {
        disable_public_ip_addresses = true
      }
      workstations = {
        my-workstation = {
          labels = {
            team = "my-team"
          }
        }
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=private-cluster.yaml
```

## Custom image

Example showing how to create a cluster with publicly accessible workstation that run a custom image.

```hcl
module "workstation-cluster" {
  source     = "./fabric/modules/workstation-cluster"
  project_id = var.project_id
  id         = "my-workstation-cluster"
  location   = var.region
  network_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
  workstation_configs = {
    my-workstation-config = {
      container = {
        image = "repo/my-image:v10.0.0"
        args  = ["--arg1", "value1", "--arg2", "value2"]
        env = {
          VAR1 = "VALUE1"
          VAR2 = "VALUE2"
        }
        working_dir = "/my-dir"
      }
      workstations = {
        my-workstation = {
          labels = {
            team = "my-team"
          }
        }
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=custom-image.yaml
```

## IAM

Example showing how to grant IAM roles on the workstation configuration or workstation.

```hcl
module "workstation-cluster" {
  source     = "./fabric/modules/workstation-cluster"
  project_id = var.project_id
  id         = "my-workstation-cluster"
  location   = var.region
  network_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
  workstation_configs = {
    my-workstation-config = {
      workstations = {
        my-workstation = {
          labels = {
            team = "my-team"
          }
          iam = {
            "roles/workstations.user" = ["user:user1@my-org.com"]
          }
        }
      }
      iam = {
        "roles/viewer" = ["group:group1@my-org.com"]
      }
      iam_bindings = {
        workstations-config-viewer = {
          role    = "roles/viewer"
          members = ["group:group2@my-org.com"]
          condition = {
            title      = "limited-access"
            expression = "resource.name.startsWith('my-')"
          }
        }
      }
      iam_bindings_additive = {
        workstations-config-editor = {
          role   = "roles/editor"
          member = "group:group3@my-org.com"
          condition = {
            title      = "limited-access"
            expression = "resource.name.startsWith('my-')"
          }
        }
      }
    }
  }
}
# tftest modules=1 resources=7 inventory=iam.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [id](variables.tf#L59) | Workstation cluster ID. | <code>string</code> | ✓ |  |
| [location](variables.tf#L70) | Location. | <code>string</code> | ✓ |  |
| [network_config](variables.tf#L75) | Network configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L92) | Cluster ID. | <code>string</code> | ✓ |  |
| [annotations](variables.tf#L17) | Workstation cluster annotations. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L23) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [display_name](variables.tf#L38) | Display name. | <code>string</code> |  | <code>null</code> |
| [domain](variables.tf#L44) | Domain. | <code>string</code> |  | <code>null</code> |
| [factories_config](variables.tf#L50) | Path to folder with YAML resource description data files. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L64) | Workstation cluster labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [private_cluster_config](variables.tf#L83) | Private cluster config. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [workstation_configs](variables.tf#L97) | Workstation configurations. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cluster_hostname](outputs.tf#L17) | Cluster hostname. |  |
| [id](outputs.tf#L22) | Workstation cluster id. |  |
| [service_attachment_uri](outputs.tf#L27) | Workstation service attachment URI. |  |
| [workstation_configs](outputs.tf#L32) | Workstation configurations. |  |
| [workstations](outputs.tf#L37) | Workstations. |  |
<!-- END TFDOC -->
