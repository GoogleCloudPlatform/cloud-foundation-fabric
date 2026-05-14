# GKE nodepool module

This module allows simplified creation and management of individual GKE nodepools, setting sensible defaults (eg a service account is created for nodes if none is set) and allowing for less verbose usage in most use cases.

## Example usage

### Module defaults

If no specific node configuration is set via variables, the module uses the provider's defaults only setting OAuth scopes to a minimal working set and the node machine type to `n1-standard-1`. The service account set by the provider in this case is the GCE default service account.

```hcl
module "cluster-1-nodepool-1" {
  source       = "./fabric/modules/gke-nodepool"
  project_id   = "myproject"
  cluster_name = "cluster-1"
  location     = "europe-west1-b"
  name         = "nodepool-1"
}
# tftest modules=1 resources=1 inventory=basic.yaml
```

### Internally managed service account

There are three different approaches to defining the nodes service account, all depending on the `service_account` variable where the `create` attribute controls creation of a new service account by this module, and the `email` attribute controls the actual service account to use.

If you create a new service account, its resource and email (in both plain and IAM formats) are then available in outputs to reference it in other modules or resources.

#### GCE default service account

To use the GCE default service account, you can ignore the variable which is equivalent to `{ create = null, email = null }`. This is what the first example of this document does.

#### Externally defined service account

To use an existing service account, pass in just the `email` attribute. If you do this, will most likely want to use the `cloud-platform` scope.

```hcl
module "cluster-1-nodepool-1" {
  source       = "./fabric/modules/gke-nodepool"
  project_id   = "myproject"
  cluster_name = "cluster-1"
  location     = "europe-west1-b"
  name         = "nodepool-1"
  service_account = {
    email        = "foo-bar@myproject.iam.gserviceaccount.com"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
# tftest modules=1 resources=1 inventory=external-sa.yaml
```

#### Auto-created service account

To have the module create a service account, set the `create` attribute to `true` and optionally pass the desired account id in `email`.

```hcl
module "cluster-1-nodepool-1" {
  source       = "./fabric/modules/gke-nodepool"
  project_id   = "myproject"
  cluster_name = "cluster-1"
  location     = "europe-west1-b"
  name         = "nodepool-1"
  service_account = {
    create       = true
    email        = "spam-eggs" # optional
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
# tftest modules=1 resources=2 inventory=create-sa.yaml
```

### Node & node pool configuration

```hcl
module "cluster-1-nodepool-1" {
  source       = "./fabric/modules/gke-nodepool"
  project_id   = "myproject"
  cluster_name = "cluster-1"
  location     = "europe-west1-b"
  name         = "nodepool-1"
  k8s_labels   = { environment = "dev" }
  service_account = {
    create       = true
    email        = "nodepool-1" # optional
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  node_config = {
    machine_type        = "n2-standard-2"
    disk_size_gb        = 50
    disk_type           = "pd-ssd"
    ephemeral_ssd_count = 1
    gvnic               = true
    spot                = true
  }
  nodepool_config = {
    autoscaling = {
      max_node_count = 10
      min_node_count = 1
    }
    management = {
      auto_repair  = true
      auto_upgrade = false
    }
  }
}
# tftest modules=1 resources=2 inventory=config.yaml
```

### GPU Node & node pool configuration

```hcl
module "cluster-1-nodepool-gpu-1" {
  source       = "./fabric/modules/gke-nodepool"
  project_id   = "myproject"
  cluster_name = "cluster-1"
  location     = "europe-west4-a"
  name         = "nodepool-gpu-1"
  k8s_labels   = { environment = "dev" }
  service_account = {
    create       = true
    email        = "nodepool-gpu-1" # optional
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  node_config = {
    machine_type        = "a2-highgpu-1g"
    disk_size_gb        = 50
    disk_type           = "pd-ssd"
    ephemeral_ssd_count = 1
    gvnic               = true
    spot                = true
    guest_accelerator = {
      type  = "nvidia-tesla-a100"
      count = 1
      gpu_driver = {
        version = "LATEST"
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=guest-accelerator.yaml
```

### Dynamic Workload Scheduler (DWS) & node pool configuration

This example uses Dynamic Workload Scheduler (DWS) to configure a GPU nodepool.

```hcl
module "cluster-1-nodepool-dws" {
  source       = "./fabric/modules/gke-nodepool"
  project_id   = "myproject"
  cluster_name = "cluster-1"
  location     = "europe-west4-a"
  name         = "nodepool-dws"
  k8s_labels   = { environment = "dev" }
  service_account = {
    create       = true
    email        = "nodepool-gpu-1" # optional
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  node_config = {
    machine_type        = "g2-standard-4"
    disk_size_gb        = 50
    disk_type           = "pd-ssd"
    ephemeral_ssd_count = 1
    gvnic               = true
    spot                = true
    guest_accelerator = {
      type  = "nvidia-l4"
      count = 1
      gpu_driver = {
        version = "LATEST"
      }
    }
  }
  nodepool_config = {
    autoscaling = {
      max_node_count = 10
      min_node_count = 0
    }
    queued_provisioning = true
  }
  node_count = {
    initial = 0
  }
  reservation_affinity = {
    consume_reservation_type = "NO_RESERVATION"
  }
}
# tftest modules=1 resources=2 inventory=dws.yaml
```
### Hyperdisk Balanced

This example shows how to configure Hyperdisk Balanced with provisioned IOPS and throughput.

```hcl
module "cluster-1-nodepool-hyperdisk" {
  source       = "./fabric/modules/gke-nodepool"
  project_id   = "myproject"
  cluster_name = "cluster-1"
  location     = "europe-west4-a"
  name         = "nodepool-hyperdisk"
  node_config = {
    machine_type = "c3-standard-4"
    boot_disk = {
      image_type             = "COS_CONTAINERD"
      type                   = "hyperdisk-balanced"
      size_gb                = 100
      provisioned_iops       = 3000
      provisioned_throughput = 140
    }
  }
}
# tftest modules=1 resources=1 inventory=hyperdisk.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cluster_name](variables.tf#L23) | Cluster name. | <code>string</code> | ✓ |  |
| [location](variables.tf#L48) | Cluster location. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L224) | Cluster project id. | <code>string</code> | ✓ |  |
| [cluster_id](variables.tf#L17) | Cluster id. Optional, but providing cluster_id is recommended to prevent cluster misconfiguration in some of the edge cases. | <code>string</code> |  | <code>null</code> |
| [gke_version](variables.tf#L28) | Kubernetes nodes version. Ignored if auto_upgrade is set in management_config. | <code>string</code> |  | <code>null</code> |
| [k8s_labels](variables.tf#L34) | Kubernetes labels applied to each node. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L41) | The resource labels to be applied each node (vm). | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [max_pods_per_node](variables.tf#L53) | Maximum number of pods per node. | <code>number</code> |  | <code>null</code> |
| [name](variables.tf#L59) | Optional nodepool name. | <code>string</code> |  | <code>null</code> |
| [network_config](variables.tf#L65) | Network configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [node_config](variables.tf#L89) | Node-level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [node_count](variables.tf#L170) | Number of nodes per instance group. Initial value can only be changed by recreation, current is ignored when autoscaling is used. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [node_locations](variables.tf#L182) | Node locations. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [nodepool_config](variables.tf#L188) | Nodepool-level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [reservation_affinity](variables.tf#L229) | Configuration of the desired reservation which instances could take capacity from. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [resource_manager_tags](variables.tf#L239) | A map of resource manager tag keys and values to be attached to the nodes for managing Compute Engine firewalls using Network Firewall Policies. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [service_account](variables.tf#L245) | Nodepool service account. If this variable is set to null, the default GCE service account will be used. If set and email is null, a service account will be created. If scopes are null a default will be used. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [sole_tenant_nodegroup](variables.tf#L257) | Sole tenant node group. | <code>string</code> |  | <code>null</code> |
| [tags](variables.tf#L263) | Network tags applied to nodes. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [taints](variables.tf#L269) | Kubernetes taints applied to all nodes. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified nodepool id. |  |
| [name](outputs.tf#L22) | Nodepool name. |  |
| [service_account_email](outputs.tf#L27) | Service account email. |  |
| [service_account_iam_email](outputs.tf#L32) | Service account email. |  |
<!-- END TFDOC -->
