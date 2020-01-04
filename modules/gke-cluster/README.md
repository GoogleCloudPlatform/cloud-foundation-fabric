# Minimalistic GKE module

TODO(ludoo): add description.

## Example usage

TODO(ludoo): add example

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| location | Cluster zone or region. | <code title="">string</code> | ✓ |  |
| name | Cluster name. | <code title="">string</code> | ✓ |  |
| network | Name or self link of the VPC used for the cluster. Use the self link for Shared VPC. | <code title="">string</code> | ✓ |  |
| project_id | Cluster project id. | <code title="">string</code> | ✓ |  |
| secondary_range_pods | Subnet secondary range name used for pods. | <code title="">string</code> | ✓ |  |
| secondary_range_services | Subnet secondary range name used for services. | <code title="">string</code> | ✓ |  |
| subnetwork | VPC subnetwork name or self link. | <code title="">string</code> | ✓ |  |
| *addons* | Addons enabled in the cluster (true means enabled). | <code title="object&#40;&#123;&#10;horizontal_pod_autoscaling &#61; bool&#10;http_load_balancing        &#61; bool&#10;network_policy_config      &#61; bool&#10;cloudrun_config            &#61; bool&#10;istio_config &#61; object&#40;&#123;&#10;enabled &#61; bool&#10;tls     &#61; bool&#10;&#125;&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;horizontal_pod_autoscaling &#61; true&#10;http_load_balancing        &#61; true&#10;network_policy_config      &#61; false&#10;cloudrun_config            &#61; false&#10;istio_config &#61; &#123;&#10;enabled &#61; false&#10;tls     &#61; false&#10;&#125;&#10;&#125;">...</code> |
| *authenticator_security_group* | RBAC security group for Google Groups for GKE, format is gke-security-groups@yourdomain.com. | <code title="">string</code> |  | <code title="">null</code> |
| *cluster_autoscaling* | Enable and configure limits for Node Auto-Provisioning with Cluster Autoscaler. | <code title="object&#40;&#123;&#10;enabled    &#61; bool&#10;cpu_min    &#61; number&#10;cpu_max    &#61; number&#10;memory_min &#61; number&#10;memory_max &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;enabled    &#61; false&#10;cpu_min    &#61; 0&#10;cpu_max    &#61; 0&#10;memory_min &#61; 0&#10;memory_max &#61; 0&#10;&#125;">...</code> |
| *database_encryption* | Enable and configure GKE application-layer secrets encryption. | <code title="object&#40;&#123;&#10;enabled  &#61; bool&#10;state    &#61; string&#10;key_name &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;enabled  &#61; false&#10;state    &#61; &#34;DECRYPTED&#34;&#10;key_name &#61; null&#10;&#125;">...</code> |
| *default_max_pods_per_node* | Maximum number of pods per node in this cluster. | <code title="">number</code> |  | <code title="">110</code> |
| *description* | Cluster description. | <code title="">string</code> |  | <code title="">null</code> |
| *enable_binary_authorization* | Enable Google Binary Authorization. | <code title="">bool</code> |  | <code title="">null</code> |
| *enable_intranode_visibility* | Enable intra-node visibility to make same node pod to pod traffic visible. | <code title="">bool</code> |  | <code title="">null</code> |
| *enable_shielded_nodes* | Enable Shielded Nodes features on all nodes in this cluster. | <code title="">bool</code> |  | <code title="">null</code> |
| *enable_tpu* | Enable Cloud TPU resources in this cluster. | <code title="">bool</code> |  | <code title="">null</code> |
| *labels* | Cluster resource labels. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">null</code> |
| *logging_service* | Logging service (disable with an empty string). | <code title="">string</code> |  | <code title="">logging.googleapis.com/kubernetes</code> |
| *maintenance_start_time* | Maintenance start time in RFC3339 format 'HH:MM', where HH is [00-23] and MM is [00-59] GMT. | <code title="">string</code> |  | <code title="">03:00</code> |
| *master_authorized_ranges* | External Ip address ranges that can access the Kubernetes cluster master through HTTPS. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *min_master_version* | Minimum version of the master, defaults to the version of the most recent official release. | <code title="">string</code> |  | <code title="">null</code> |
| *monitoring_service* | Monitoring service (disable with an empty string). | <code title="">string</code> |  | <code title="">monitoring.googleapis.com/kubernetes</code> |
| *node_locations* | Zones in which the cluster's nodes are located. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *pod_security_policy* | Enable the PodSecurityPolicy feature. | <code title="">bool</code> |  | <code title="">null</code> |
| *private_cluster_config* | Enable and configure private cluster. | <code title="object&#40;&#123;&#10;enable_private_nodes    &#61; bool&#10;enable_private_endpoint &#61; bool&#10;master_ipv4_cidr_block  &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *release_channel* | Release channel for GKE upgrades. | <code title="">string</code> |  | <code title="">null</code> |
| *resource_usage_export_config* | Configure the ResourceUsageExportConfig feature. | <code title="object&#40;&#123;&#10;enabled &#61; bool&#10;dataset &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;enabled &#61; null&#10;dataset &#61; null&#10;&#125;">...</code> |
| *vertical_pod_autoscaling* | Enable the Vertical Pod Autoscaling feature. | <code title="">bool</code> |  | <code title="">null</code> |
| *workload_identity* | Enable the Workload Identity feature. | <code title="">bool</code> |  | <code title="">true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| cluster | Cluster resource. | ✓ |
| endpoint | Cluster endpoint. |  |
| location | Cluster location. |  |
| master_version | Master version. |  |
| name | Cluster name. |  |
<!-- END TFDOC -->
