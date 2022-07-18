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
# tftest modules=1 resources=2
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cluster_name](variables.tf#L26) | Cluster name. | <code>string</code> | ✓ |  |
| [location](variables.tf#L59) | Cluster location. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L216) | Cluster project id. | <code>string</code> | ✓ |  |
| [autoscaling_config](variables.tf#L17) | Optional autoscaling configuration. | <code title="object&#40;&#123;&#10;  min_node_count &#61; number&#10;  max_node_count &#61; number&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [gke_version](variables.tf#L31) | Kubernetes nodes version. Ignored if auto_upgrade is set in management_config. | <code>string</code> |  | <code>null</code> |
| [initial_node_count](variables.tf#L37) | Initial number of nodes for the pool. | <code>number</code> |  | <code>1</code> |
| [kubelet_config](variables.tf#L43) | Kubelet configuration. | <code title="object&#40;&#123;&#10;  cpu_cfs_quota        &#61; string&#10;  cpu_cfs_quota_period &#61; string&#10;  cpu_manager_policy   &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [linux_node_config_sysctls](variables.tf#L53) | Linux node configuration. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [management_config](variables.tf#L64) | Optional node management configuration. | <code title="object&#40;&#123;&#10;  auto_repair  &#61; bool&#10;  auto_upgrade &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [max_pods_per_node](variables.tf#L73) | Maximum number of pods per node. | <code>number</code> |  | <code>null</code> |
| [name](variables.tf#L79) | Optional nodepool name. | <code>string</code> |  | <code>null</code> |
| [node_boot_disk_kms_key](variables.tf#L85) | Customer Managed Encryption Key used to encrypt the boot disk attached to each node. | <code>string</code> |  | <code>null</code> |
| [node_count](variables.tf#L91) | Number of nodes per instance group, can be updated after creation. Ignored when autoscaling is set. | <code>number</code> |  | <code>null</code> |
| [node_disk_size](variables.tf#L97) | Node disk size, defaults to 100GB. | <code>number</code> |  | <code>100</code> |
| [node_disk_type](variables.tf#L103) | Node disk type, defaults to pd-standard. | <code>string</code> |  | <code>&#34;pd-standard&#34;</code> |
| [node_guest_accelerator](variables.tf#L109) | Map of type and count of attached accelerator cards. | <code>map&#40;number&#41;</code> |  | <code>&#123;&#125;</code> |
| [node_image_type](variables.tf#L115) | Nodes image type. | <code>string</code> |  | <code>null</code> |
| [node_labels](variables.tf#L121) | Kubernetes labels attached to nodes. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [node_local_ssd_count](variables.tf#L127) | Number of local SSDs attached to nodes. | <code>number</code> |  | <code>0</code> |
| [node_locations](variables.tf#L132) | Optional list of zones in which nodes should be located. Uses cluster locations if unset. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [node_machine_type](variables.tf#L138) | Nodes machine type. | <code>string</code> |  | <code>&#34;n1-standard-1&#34;</code> |
| [node_metadata](variables.tf#L144) | Metadata key/value pairs assigned to nodes. Set disable-legacy-endpoints to true when using this variable. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [node_min_cpu_platform](variables.tf#L150) | Minimum CPU platform for nodes. | <code>string</code> |  | <code>null</code> |
| [node_preemptible](variables.tf#L156) | Use preemptible VMs for nodes. | <code>bool</code> |  | <code>null</code> |
| [node_sandbox_config](variables.tf#L162) | GKE Sandbox configuration. Needs image_type set to COS_CONTAINERD and node_version set to 1.12.7-gke.17 when using this variable. | <code>string</code> |  | <code>null</code> |
| [node_service_account](variables.tf#L168) | Service account email. Unused if service account is auto-created. | <code>string</code> |  | <code>null</code> |
| [node_service_account_create](variables.tf#L174) | Auto-create service account. | <code>bool</code> |  | <code>false</code> |
| [node_service_account_scopes](variables.tf#L182) | Scopes applied to service account. Default to: 'cloud-platform' when creating a service account; 'devstorage.read_only', 'logging.write', 'monitoring.write' otherwise. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [node_shielded_instance_config](variables.tf#L188) | Shielded instance options. | <code title="object&#40;&#123;&#10;  enable_secure_boot          &#61; bool&#10;  enable_integrity_monitoring &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [node_spot](variables.tf#L197) | Use Spot VMs for nodes. | <code>bool</code> |  | <code>null</code> |
| [node_tags](variables.tf#L203) | Network tags applied to nodes. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [node_taints](variables.tf#L209) | Kubernetes taints applied to nodes. E.g. type=blue:NoSchedule. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [upgrade_config](variables.tf#L221) | Optional node upgrade configuration. | <code title="object&#40;&#123;&#10;  max_surge       &#61; number&#10;  max_unavailable &#61; number&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [workload_metadata_config](variables.tf#L230) | Metadata configuration to expose to workloads on the node pool. | <code>string</code> |  | <code>&#34;GKE_METADATA&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [name](outputs.tf#L17) | Nodepool name. |  |
| [service_account](outputs.tf#L22) | Service account resource. |  |
| [service_account_email](outputs.tf#L31) | Service account email. |  |
| [service_account_iam_email](outputs.tf#L36) | Service account email. |  |

<!-- END TFDOC -->
