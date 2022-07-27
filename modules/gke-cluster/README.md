# GKE cluster module

This module allows simplified creation and management of GKE clusters and should be used together with the GKE nodepool module, as the default nodepool is turned off here and cannot be re-enabled. Some sensible defaults are set initially, in order to allow less verbose usage for most use cases.

## Example

### GKE Cluster

```hcl
module "cluster-1" {
  source                    = "./modules/gke-cluster"
  project_id                = "myproject"
  name                      = "cluster-1"
  location                  = "europe-west1-b"
  network                   = var.vpc.self_link
  subnetwork                = var.subnet.self_link
  secondary_range_pods      = "pods"
  secondary_range_services  = "services"
  default_max_pods_per_node = 32
  master_authorized_ranges = {
    internal-vms = "10.0.0.0/8"
  }
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "192.168.0.0/28"
    master_global_access    = false
  }
  labels = {
    environment = "dev"
  }
}
# tftest modules=1 resources=1
```

### GKE Cluster with Dataplane V2 enabled

```hcl
module "cluster-1" {
  source                    = "./modules/gke-cluster"
  project_id                = "myproject"
  name                      = "cluster-1"
  location                  = "europe-west1-b"
  network                   = var.vpc.self_link
  subnetwork                = var.subnet.self_link
  secondary_range_pods      = "pods"
  secondary_range_services  = "services"
  default_max_pods_per_node = 32
  enable_dataplane_v2       = true
  master_authorized_ranges = {
    internal-vms = "10.0.0.0/8"
  }
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "192.168.0.0/28"
    master_global_access    = false
  }
  labels = {
    environment = "dev"
  }
}
# tftest modules=1 resources=1
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location](variables.tf#L161) | Cluster zone or region. | <code>string</code> | ✓ |  |
| [name](variables.tf#L228) | Cluster name. | <code>string</code> | ✓ |  |
| [network](variables.tf#L233) | Name or self link of the VPC used for the cluster. Use the self link for Shared VPC. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L277) | Cluster project id. | <code>string</code> | ✓ |  |
| [secondary_range_pods](variables.tf#L300) | Subnet secondary range name used for pods. | <code>string</code> | ✓ |  |
| [secondary_range_services](variables.tf#L305) | Subnet secondary range name used for services. | <code>string</code> | ✓ |  |
| [subnetwork](variables.tf#L310) | VPC subnetwork name or self link. | <code>string</code> | ✓ |  |
| [addons](variables.tf#L17) | Addons enabled in the cluster (true means enabled). | <code title="object&#40;&#123;&#10;  cloudrun_config            &#61; bool&#10;  dns_cache_config           &#61; bool&#10;  horizontal_pod_autoscaling &#61; bool&#10;  http_load_balancing        &#61; bool&#10;  istio_config &#61; object&#40;&#123;&#10;    enabled &#61; bool&#10;    tls     &#61; bool&#10;  &#125;&#41;&#10;  network_policy_config                 &#61; bool&#10;  gce_persistent_disk_csi_driver_config &#61; bool&#10;  gcp_filestore_csi_driver_config       &#61; bool&#10;  config_connector_config               &#61; bool&#10;  kalm_config                           &#61; bool&#10;  gke_backup_agent_config               &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  cloudrun_config            &#61; false&#10;  dns_cache_config           &#61; false&#10;  horizontal_pod_autoscaling &#61; true&#10;  http_load_balancing        &#61; true&#10;  istio_config &#61; &#123;&#10;    enabled &#61; false&#10;    tls     &#61; false&#10;  &#125;&#10;  network_policy_config                 &#61; false&#10;  gce_persistent_disk_csi_driver_config &#61; false&#10;  gcp_filestore_csi_driver_config       &#61; false&#10;  config_connector_config               &#61; false&#10;  kalm_config                           &#61; false&#10;  gke_backup_agent_config               &#61; false&#10;&#125;">&#123;&#8230;&#125;</code> |
| [authenticator_security_group](variables.tf#L53) | RBAC security group for Google Groups for GKE, format is gke-security-groups@yourdomain.com. | <code>string</code> |  | <code>null</code> |
| [cluster_autoscaling](variables.tf#L59) | Enable and configure limits for Node Auto-Provisioning with Cluster Autoscaler. | <code title="object&#40;&#123;&#10;  enabled    &#61; bool&#10;  cpu_min    &#61; number&#10;  cpu_max    &#61; number&#10;  memory_min &#61; number&#10;  memory_max &#61; number&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled    &#61; false&#10;  cpu_min    &#61; 0&#10;  cpu_max    &#61; 0&#10;  memory_min &#61; 0&#10;  memory_max &#61; 0&#10;&#125;">&#123;&#8230;&#125;</code> |
| [database_encryption](variables.tf#L77) | Enable and configure GKE application-layer secrets encryption. | <code title="object&#40;&#123;&#10;  enabled  &#61; bool&#10;  state    &#61; string&#10;  key_name &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled  &#61; false&#10;  state    &#61; &#34;DECRYPTED&#34;&#10;  key_name &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [default_max_pods_per_node](variables.tf#L91) | Maximum number of pods per node in this cluster. | <code>number</code> |  | <code>110</code> |
| [description](variables.tf#L97) | Cluster description. | <code>string</code> |  | <code>null</code> |
| [dns_config](variables.tf#L103) | Configuration for Using Cloud DNS for GKE. | <code title="object&#40;&#123;&#10;  cluster_dns        &#61; string&#10;  cluster_dns_scope  &#61; string&#10;  cluster_dns_domain &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [enable_autopilot](variables.tf#L113) | Create cluster in autopilot mode. With autopilot there's no need to create node-pools and some features are not supported (e.g. setting default_max_pods_per_node). | <code>bool</code> |  | <code>false</code> |
| [enable_binary_authorization](variables.tf#L119) | Enable Google Binary Authorization. | <code>bool</code> |  | <code>null</code> |
| [enable_dataplane_v2](variables.tf#L125) | Enable Dataplane V2 on the cluster, will disable network_policy addons config. | <code>bool</code> |  | <code>false</code> |
| [enable_intranode_visibility](variables.tf#L131) | Enable intra-node visibility to make same node pod to pod traffic visible. | <code>bool</code> |  | <code>null</code> |
| [enable_l4_ilb_subsetting](variables.tf#L137) | Enable L4ILB Subsetting. | <code>bool</code> |  | <code>null</code> |
| [enable_shielded_nodes](variables.tf#L143) | Enable Shielded Nodes features on all nodes in this cluster. | <code>bool</code> |  | <code>null</code> |
| [enable_tpu](variables.tf#L149) | Enable Cloud TPU resources in this cluster. | <code>bool</code> |  | <code>null</code> |
| [labels](variables.tf#L155) | Cluster resource labels. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [logging_config](variables.tf#L166) | Logging configuration (enabled components). | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [logging_service](variables.tf#L172) | Logging service (disable with an empty string). | <code>string</code> |  | <code>&#34;logging.googleapis.com&#47;kubernetes&#34;</code> |
| [maintenance_config](variables.tf#L178) | Maintenance window configuration. | <code title="object&#40;&#123;&#10;  daily_maintenance_window &#61; object&#40;&#123;&#10;    start_time &#61; string&#10;  &#125;&#41;&#10;  recurring_window &#61; object&#40;&#123;&#10;    start_time &#61; string&#10;    end_time   &#61; string&#10;    recurrence &#61; string&#10;  &#125;&#41;&#10;  maintenance_exclusion &#61; list&#40;object&#40;&#123;&#10;    exclusion_name &#61; string&#10;    start_time     &#61; string&#10;    end_time       &#61; string&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  daily_maintenance_window &#61; &#123;&#10;    start_time &#61; &#34;03:00&#34;&#10;  &#125;&#10;  recurring_window      &#61; null&#10;  maintenance_exclusion &#61; &#91;&#93;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [master_authorized_ranges](variables.tf#L204) | External Ip address ranges that can access the Kubernetes cluster master through HTTPS. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [min_master_version](variables.tf#L210) | Minimum version of the master, defaults to the version of the most recent official release. | <code>string</code> |  | <code>null</code> |
| [monitoring_config](variables.tf#L216) | Monitoring configuration (enabled components). | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [monitoring_service](variables.tf#L222) | Monitoring service (disable with an empty string). | <code>string</code> |  | <code>&#34;monitoring.googleapis.com&#47;kubernetes&#34;</code> |
| [node_locations](variables.tf#L238) | Zones in which the cluster's nodes are located. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [notification_config](variables.tf#L244) | GKE Cluster upgrade notifications via PubSub. | <code>bool</code> |  | <code>false</code> |
| [peering_config](variables.tf#L250) | Configure peering with the master VPC for private clusters. | <code title="object&#40;&#123;&#10;  export_routes &#61; bool&#10;  import_routes &#61; bool&#10;  project_id    &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [pod_security_policy](variables.tf#L260) | Enable the PodSecurityPolicy feature. | <code>bool</code> |  | <code>null</code> |
| [private_cluster_config](variables.tf#L266) | Enable and configure private cluster, private nodes must be true if used. | <code title="object&#40;&#123;&#10;  enable_private_nodes    &#61; bool&#10;  enable_private_endpoint &#61; bool&#10;  master_ipv4_cidr_block  &#61; string&#10;  master_global_access    &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [release_channel](variables.tf#L282) | Release channel for GKE upgrades. | <code>string</code> |  | <code>null</code> |
| [resource_usage_export_config](variables.tf#L288) | Configure the ResourceUsageExportConfig feature. | <code title="object&#40;&#123;&#10;  enabled &#61; bool&#10;  dataset &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled &#61; null&#10;  dataset &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [vertical_pod_autoscaling](variables.tf#L315) | Enable the Vertical Pod Autoscaling feature. | <code>bool</code> |  | <code>null</code> |
| [workload_identity](variables.tf#L321) | Enable the Workload Identity feature. | <code>bool</code> |  | <code>true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [ca_certificate](outputs.tf#L17) | Public certificate of the cluster (base64-encoded). | ✓ |
| [cluster](outputs.tf#L23) | Cluster resource. | ✓ |
| [endpoint](outputs.tf#L29) | Cluster endpoint. |  |
| [id](outputs.tf#L34) | Cluster ID. |  |
| [location](outputs.tf#L39) | Cluster location. |  |
| [master_version](outputs.tf#L44) | Master version. |  |
| [name](outputs.tf#L49) | Cluster name. |  |
| [notifications](outputs.tf#L54) | GKE PubSub notifications topic. |  |
| [self_link](outputs.tf#L59) | Cluster self link. | ✓ |

<!-- END TFDOC -->
