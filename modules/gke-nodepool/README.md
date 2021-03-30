# GKE nodepool module

This module allows simplified creation and management of individual GKE nodepools, setting sensible defaults (eg a service account is created for nodes if none is set) and allowing for less verbose usage in most use cases.

## Example usage

### Module defaults

If no specific node configuration is set via variables, the module uses the provider's defaults only setting OAuth scopes to a minimal working set (devstorage read-only, logging and monitoring write) and the node machine type to `n1-standard-1`. The service account set by the provider in this case is the GCE default service account.

```hcl
module "cluster-1-nodepool-1" {
  source                      = "./modules/gke-nodepool"
  project_id                  = "myproject"
  cluster_name                = "cluster-1"
  location                    = "europe-west1-b"
  name                        = "nodepool-1"
}
```

### Internally managed service account

To have the module auto-create a service account for the nodes, set the `node_service_account_create` variable to `true`. When a service account is created by the module, OAuth scopes are set to `cloud-platform` by default. The service account resource and email (in both plain and IAM formats) are then available in outputs to assign IAM roles from your own code.

```hcl
module "cluster-1-nodepool-1" {
  source                      = "./modules/gke-nodepool"
  project_id                  = "myproject"
  cluster_name                = "cluster-1"
  location                    = "europe-west1-b"
  name                        = "nodepool-1"
  node_service_account_create = true
}
# tftest:modules=1:resources=2
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| cluster_name | Cluster name. | <code title="">string</code> | ✓ |  |
| location | Cluster location. | <code title="">string</code> | ✓ |  |
| project_id | Cluster project id. | <code title="">string</code> | ✓ |  |
| *autoscaling_config* | Optional autoscaling configuration. | <code title="object&#40;&#123;&#10;min_node_count &#61; number&#10;max_node_count &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *gke_version* | Kubernetes nodes version. Ignored if auto_upgrade is set in management_config. | <code title="">string</code> |  | <code title="">null</code> |
| *initial_node_count* | Initial number of nodes for the pool. | <code title="">number</code> |  | <code title="">1</code> |
| *management_config* | Optional node management configuration. | <code title="object&#40;&#123;&#10;auto_repair  &#61; bool&#10;auto_upgrade &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *max_pods_per_node* | Maximum number of pods per node. | <code title="">number</code> |  | <code title="">null</code> |
| *name* | Optional nodepool name. | <code title="">string</code> |  | <code title="">null</code> |
| *node_boot_disk_kms_key* | Customer Managed Encryption Key used to encrypt the boot disk attached to each node | <code title="">string</code> |  | <code title="">null</code> |
| *node_count* | Number of nodes per instance group, can be updated after creation. Ignored when autoscaling is set. | <code title="">number</code> |  | <code title="">null</code> |
| *node_disk_size* | Node disk size, defaults to 100GB. | <code title="">number</code> |  | <code title="">100</code> |
| *node_disk_type* | Node disk type, defaults to pd-standard. | <code title="">string</code> |  | <code title="">pd-standard</code> |
| *node_guest_accelerator* | Map of type and count of attached accelerator cards. | <code title="map&#40;number&#41;">map(number)</code> |  | <code title="">{}</code> |
| *node_image_type* | Nodes image type. | <code title="">string</code> |  | <code title="">null</code> |
| *node_labels* | Kubernetes labels attached to nodes. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *node_local_ssd_count* | Number of local SSDs attached to nodes. | <code title="">number</code> |  | <code title="">0</code> |
| *node_locations* | Optional list of zones in which nodes should be located. Uses cluster locations if unset. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">null</code> |
| *node_machine_type* | Nodes machine type. | <code title="">string</code> |  | <code title="">n1-standard-1</code> |
| *node_metadata* | Metadata key/value pairs assigned to nodes. Set disable-legacy-endpoints to true when using this variable. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">null</code> |
| *node_min_cpu_platform* | Minimum CPU platform for nodes. | <code title="">string</code> |  | <code title="">null</code> |
| *node_preemptible* | Use preemptible VMs for nodes. | <code title="">bool</code> |  | <code title="">null</code> |
| *node_sandbox_config* | GKE Sandbox configuration. Needs image_type set to COS_CONTAINERD and node_version set to 1.12.7-gke.17 when using this variable. | <code title="">string</code> |  | <code title="">null</code> |
| *node_service_account* | Service account email. Unused if service account is auto-created. | <code title="">string</code> |  | <code title="">null</code> |
| *node_service_account_create* | Auto-create service account. | <code title="">bool</code> |  | <code title="">false</code> |
| *node_service_account_scopes* | Scopes applied to service account. Default to: 'cloud-platform' when creating a service account; 'devstorage.read_only', 'logging.write', 'monitoring.write' otherwise. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *node_shielded_instance_config* | Shielded instance options. | <code title="object&#40;&#123;&#10;enable_secure_boot          &#61; bool&#10;enable_integrity_monitoring &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *node_tags* | Network tags applied to nodes. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">null</code> |
| *node_taints* | Kubernetes taints applied to nodes. E.g. type=blue:NoSchedule | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *upgrade_config* | Optional node upgrade configuration. | <code title="object&#40;&#123;&#10;max_surge       &#61; number&#10;max_unavailable &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *workload_metadata_config* | Metadata configuration to expose to workloads on the node pool. | <code title="">string</code> |  | <code title="">GKE_METADATA_SERVER</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| name | Nodepool name. |  |
| service_account | Service account resource. |  |
| service_account_email | Service account email. |  |
| service_account_iam_email | Service account email. |  |
<!-- END TFDOC -->
