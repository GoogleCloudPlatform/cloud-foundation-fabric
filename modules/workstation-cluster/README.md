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
| [id](variables.tf#L35) | Workstation cluster ID. | <code>string</code> | ✓ |  |
| [location](variables.tf#L46) | Location. | <code>string</code> | ✓ |  |
| [network_config](variables.tf#L51) | Network configuration. | <code title="object&#40;&#123;&#10;  network    &#61; string&#10;  subnetwork &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L69) | Cluster ID. | <code>string</code> | ✓ |  |
| [workstation_configs](variables.tf#L74) | Workstation configurations. | <code title="map&#40;object&#40;&#123;&#10;  annotations &#61; optional&#40;map&#40;string&#41;&#41;&#10;  container &#61; optional&#40;object&#40;&#123;&#10;    image       &#61; optional&#40;string&#41;&#10;    command     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    args        &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    working_dir &#61; optional&#40;string&#41;&#10;    env         &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    run_as_user &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  display_name       &#61; optional&#40;string&#41;&#10;  enable_audit_agent &#61; optional&#40;bool&#41;&#10;  encryption_key &#61; optional&#40;object&#40;&#123;&#10;    kms_key                 &#61; string&#10;    kms_key_service_account &#61; string&#10;  &#125;&#41;&#41;&#10;  gce_instance &#61; optional&#40;object&#40;&#123;&#10;    machine_type                 &#61; optional&#40;string&#41;&#10;    service_account              &#61; optional&#40;string&#41;&#10;    service_account_scopes       &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    pool_size                    &#61; optional&#40;number&#41;&#10;    boot_disk_size_gb            &#61; optional&#40;number&#41;&#10;    tags                         &#61; optional&#40;list&#40;string&#41;&#41;&#10;    disable_public_ip_addresses  &#61; optional&#40;bool, false&#41;&#10;    enable_nested_virtualization &#61; optional&#40;bool, false&#41;&#10;    shielded_instance_config &#61; optional&#40;object&#40;&#123;&#10;      enable_secure_boot          &#61; optional&#40;bool, false&#41;&#10;      enable_vtpm                 &#61; optional&#40;bool, false&#41;&#10;      enable_integrity_monitoring &#61; optional&#40;bool, false&#41;&#10;    &#125;&#41;&#41;&#10;    enable_confidential_compute &#61; optional&#40;bool, false&#41;&#10;    accelerators &#61; optional&#40;list&#40;object&#40;&#123;&#10;      type  &#61; optional&#40;string&#41;&#10;      count &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    role    &#61; string&#10;    members &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    role   &#61; string&#10;    member &#61; string&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  idle_timeout &#61; optional&#40;string&#41;&#10;  labels       &#61; optional&#40;map&#40;string&#41;&#41;&#10;  persistent_directories &#61; optional&#40;list&#40;object&#40;&#123;&#10;    mount_path &#61; optional&#40;string&#41;&#10;    gce_pd &#61; optional&#40;object&#40;&#123;&#10;      size_gb         &#61; optional&#40;number&#41;&#10;      fs_type         &#61; optional&#40;string&#41;&#10;      disk_type       &#61; optional&#40;string&#41;&#10;      source_snapshot &#61; optional&#40;string&#41;&#10;      reclaim_policy  &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  running_timeout &#61; optional&#40;string&#41;&#10;  replica_zones   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  workstations &#61; optional&#40;map&#40;object&#40;&#123;&#10;    annotations  &#61; optional&#40;map&#40;string&#41;&#41;&#10;    display_name &#61; optional&#40;string&#41;&#10;    env          &#61; optional&#40;map&#40;string&#41;&#41;&#10;    iam          &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;      role    &#61; string&#10;      members &#61; list&#40;string&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;      role   &#61; string&#10;      member &#61; string&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    labels &#61; optional&#40;map&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [annotations](variables.tf#L17) | Workstation cluster annotations. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [display_name](variables.tf#L23) | Display name. | <code>string</code> |  | <code>null</code> |
| [domain](variables.tf#L29) | Domain. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L40) | Workstation cluster labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [private_cluster_config](variables.tf#L59) | Private cluster config. | <code title="object&#40;&#123;&#10;  enable_private_endpoint &#61; optional&#40;bool, false&#41;&#10;  allowed_projects        &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cluster_hostname](outputs.tf#L17) | Cluster hostname. |  |
| [id](outputs.tf#L22) | Workstation cluster id. |  |
| [service_attachment_uri](outputs.tf#L27) | Workstation service attachment URI. |  |
| [workstation_configs](outputs.tf#L32) | Workstation configurations. |  |
| [workstations](outputs.tf#L37) | Workstations. |  |
<!-- END TFDOC -->
