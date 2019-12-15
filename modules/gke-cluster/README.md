# Minimalistic GKE module

TODO(ludoo): add description.

## Example usage

TODO(ludoo): add example

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| location | Cluster zone or region. | string | ✓
| name | Cluster name. | string | ✓
| network | Name or self link of the VPC used for the cluster. Use the self link for Shared VPC. | string | ✓
| project_id | Cluster project id. | string | ✓
| secondary_range_pods | Subnet secondary range name used for pods. | string | ✓
| secondary_range_services | Subnet secondary range name used for services. | string | ✓
| subnetwork | VPC subnetwork name or self link. | string | ✓
| *addons* | Addons enabled in the cluster (true means enabled). | object({...}) | 
| *authenticator_security_group* | RBAC security group for Google Groups for GKE, format is gke-security-groups@yourdomain.com. | string | 
| *cluster_autoscaling* | Enable and configure limits for Node Auto-Provisioning with Cluster Autoscaler. | object({...}) | 
| *database_encryption* | Enable and configure GKE application-layer secrets encryption. | object({...}) | 
| *default_max_pods_per_node* | Maximum number of pods per node in this cluster. | number | 
| *description* | Cluster description. | string | 
| *enable_binary_authorization* | Enable Google Binary Authorization. | bool | 
| *enable_intranode_visibility* | Enable intra-node visibility to make same node pod to pod traffic visible. | bool | 
| *enable_shielded_nodes* | Enable Shielded Nodes features on all nodes in this cluster. | bool | 
| *enable_tpu* | Enable Cloud TPU resources in this cluster. | bool | 
| *labels* | Cluster resource labels. | map(string) | 
| *logging_service* | Logging service (disable with an empty string). | string | 
| *maintenance_start_time* | Maintenance start time in RFC3339 format 'HH:MM', where HH is [00-23] and MM is [00-59] GMT. | string | 
| *master_authorized_ranges* | External Ip address ranges that can access the Kubernetes cluster master through HTTPS. | map(string) | 
| *min_master_version* | Minimum version of the master, defaults to the version of the most recent official release. | string | 
| *monitoring_service* | Monitoring service (disable with an empty string). | string | 
| *node_locations* | Zones in which the cluster's nodes are located. | list(string) | 
| *pod_security_policy* | Enable the PodSecurityPolicy feature. | bool | 
| *private_cluster* | Enable private cluster. | bool | 
| *private_cluster_config* | Private cluster configuration. | object({...}) | 
| *release_channel* | Release channel for GKE upgrades. | string | 
| *resource_usage_export_config* | Configure the ResourceUsageExportConfig feature. | object({...}) | 
| *vertical_pod_autoscaling* | Enable the Vertical Pod Autoscaling feature. | bool | 
| *workload_identity* | Enable the Workload Identity feature. | bool | 

## Outputs

| name | description |
|---|---|
| cluster | Cluster resource. |
| endpoint | Cluster endpoint. |
| master_version | Master version. |
| name | Cluster name. |
<!-- END TFDOC -->
