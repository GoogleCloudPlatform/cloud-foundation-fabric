# GKE nodepool module

This module allows simplified creation and management of individual GKE nodepools, setting sensible defaults (eg a service account is created for nodes if none is set) and allowing for less verbose usage in most use cases.

## Example usage

```hcl
module "cluster-1-nodepool-1" {
  source                      = "../modules/gke-nodepool"
  project_id                  = "myproject"
  cluster_name                = "cluster-1"
  location                    = "europe-west1-b"
  name                        = "nodepool-1"
}
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
| *node_config_disk_size* | Node disk size, defaults to 100GB. | <code title="">number</code> |  | <code title="">100</code> |
| *node_config_disk_type* | Node disk type, defaults to pd-standard. | <code title="">string</code> |  | <code title="">pd-standard</code> |
| *node_config_guest_accelerator* | Map of type and count of attached accelerator cards. | <code title="map&#40;number&#41;">map(number)</code> |  | <code title="">{}</code> |
| *node_config_image_type* | Nodes image type. | <code title="">string</code> |  | <code title="">null</code> |
| *node_config_labels* | Kubernetes labels attached to nodes. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *node_config_local_ssd_count* | Number of local SSDs attached to nodes. | <code title="">number</code> |  | <code title="">0</code> |
| *node_config_machine_type* | Nodes machine type. | <code title="">string</code> |  | <code title="">n1-standard-1</code> |
| *node_config_metadata* | Metadata key/value pairs assigned to nodes. Set disable-legacy-endpoints to true when using this variable. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">null</code> |
| *node_config_min_cpu_platform* | Minimum CPU platform for nodes. | <code title="">string</code> |  | <code title="">null</code> |
| *node_config_oauth_scopes* | Set of Google API scopes for the nodes service account. Include logging-write, monitoring, and storage-ro when using this variable. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["logging-write", "monitoring", "monitoring-write", "storage-ro"]</code> |
| *node_config_preemptible* | Use preemptible VMs for nodes. | <code title="">bool</code> |  | <code title="">null</code> |
| *node_config_sandbox_config* | GKE Sandbox configuration. Needs image_type set to COS_CONTAINERD and node_version set to 1.12.7-gke.17 when using this variable. | <code title="">string</code> |  | <code title="">null</code> |
| *node_config_service_account* | Service account used for nodes. | <code title="">string</code> |  | <code title="">null</code> |
| *node_config_shielded_instance_config* | Shielded instance options. | <code title="object&#40;&#123;&#10;enable_secure_boot          &#61; bool&#10;enable_integrity_monitoring &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *node_config_tags* | Network tags applied to nodes. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">null</code> |
| *node_config_workload_metadata_config* | Metadata configuration to expose to workloads on the node pool. | <code title="">string</code> |  | <code title="">SECURE</code> |
| *node_count* | Number of nodes per instance group, can be updated after creation. Ignored when autoscaling is set. | <code title="">number</code> |  | <code title="">null</code> |
| *node_locations* | Optional list of zones in which nodes should be located. Uses cluster locations if unset. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">null</code> |
| *upgrade_config* | Optional node upgrade configuration. | <code title="object&#40;&#123;&#10;max_surge       &#61; number&#10;max_unavailable &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| name | Nodepool name. |  |
<!-- END TFDOC -->
