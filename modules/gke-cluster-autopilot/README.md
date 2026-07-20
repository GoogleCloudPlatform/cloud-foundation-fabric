# GKE Autopilot cluster module

This module offers a way to create and manage Google Kubernetes Engine (GKE) [Autopilot clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview). With its sensible default settings based on best practices and authors' experience as Google Cloud practitioners, the module accommodates for many common use cases out-of-the-box, without having to rely on verbose configuration.

<!-- BEGIN TOC -->
- [GKE Autopilot cluster](#gke-autopilot-cluster)
- [Cloud DNS](#cloud-dns)
- [Logging configuration](#logging-configuration)
- [Monitoring configuration](#monitoring-configuration)
- [Backup for GKE](#backup-for-gke)
  - [Allowing access from Google Cloud services](#allowing-access-from-google-cloud-services)
  - [Disable PSC endpoint creation](#disable-psc-endpoint-creation)
- [Upgrade notifications](#upgrade-notifications)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

For an explanation of cluster access configurations, please refer to the [GKE cluster standard](../gke-cluster-standard/README.md) module.

## GKE Autopilot cluster

This example shows how to [create a GKE cluster in Autopilot mode](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-an-autopilot-cluster).

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-autopilot"
  project_id = "myproject"
  name       = "cluster-1"
  location   = "europe-west1"
  access_config = {
    ip_access = {
      authorized_ranges = {
        internal-vms = "10.0.0.0/8"
      }
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }
  labels = {
    environment = "dev"
  }
}
# tftest modules=1 resources=1 inventory=basic.yaml
```

## Cloud DNS

> [!WARNING]
> [Cloud DNS is the only DNS provider for Autopilot clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/service-discovery#cloud_dns) running version `1.25.9-gke.400` and later, and version `1.26.4-gke.500` and later. It is [pre-configured](https://cloud.google.com/kubernetes-engine/docs/resources/autopilot-standard-feature-comparison#feature-comparison) for those clusters. The following example *only* applies to Autopilot clusters running *earlier* versions.

This example shows how to [use Cloud DNS as a Kubernetes DNS provider](https://cloud.google.com/kubernetes-engine/docs/how-to/cloud-dns).

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-autopilot"
  project_id = var.project_id
  name       = "cluster-1"
  location   = "europe-west1"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {} # use default names "pods" and "services"
  }
  enable_features = {
    dns = {
      provider = "CLOUD_DNS"
      scope    = "CLUSTER_SCOPE"
      domain   = "gke.local"
    }
  }
}
# tftest modules=1 resources=1 inventory=dns.yaml
```

## Logging configuration

> [!NOTE]
> System and workload logs collection is pre-configured for Autopilot clusters and cannot be disabled.

This example shows how to [collect logs for the Kubernetes control plane components](https://cloud.google.com/stackdriver/docs/solutions/gke/installing). The logs for these components are not collected by default.

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-autopilot"
  project_id = var.project_id
  name       = "cluster-1"
  location   = "europe-west1"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {} # use default names "pods" and "services"
  }
  logging_config = {
    enable_api_server_logs         = true
    enable_scheduler_logs          = true
    enable_controller_manager_logs = true
  }
}
# tftest modules=1 resources=1 inventory=logging-config.yaml
```

## Monitoring configuration

> [!NOTE]
> [System metrics](https://cloud.google.com/stackdriver/docs/solutions/gke/managing-metrics#enable-system-metrics) collection is pre-configured for Autopilot clusters and cannot be disabled.

> [!WARNING]
> GKE **workload metrics** is deprecated and removed in GKE 1.24 and later. Workload metrics is replaced by [Google Cloud Managed Service for Prometheus](https://cloud.google.com/stackdriver/docs/managed-prometheus), which is Google's recommended way to monitor Kubernetes applications by using Cloud Monitoring.

This example shows how to [configure collection of Kubernetes control plane metrics](https://cloud.google.com/stackdriver/docs/solutions/gke/managing-metrics#enable-control-plane-metrics). These metrics are optional and are not collected by default.

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-autopilot"
  project_id = var.project_id
  name       = "cluster-1"
  location   = "europe-west1"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {} # use default names "pods" and "services"
  }
  monitoring_config = {
    enable_api_server_metrics         = true
    enable_controller_manager_metrics = true
    enable_scheduler_metrics          = true
  }
}
# tftest modules=1 resources=1 inventory=monitoring-config-control-plane.yaml
```

The next example shows how to [configure collection of kube state metrics](https://cloud.google.com/stackdriver/docs/solutions/gke/managing-metrics#enable-ksm). These metrics are optional and are not collected by default.

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-autopilot"
  project_id = var.project_id
  name       = "cluster-1"
  location   = "europe-west1"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {} # use default names "pods" and "services"
  }
  monitoring_config = {
    enable_cadvisor_metrics    = true
    enable_daemonset_metrics   = true
    enable_deployment_metrics  = true
    enable_hpa_metrics         = true
    enable_pod_metrics         = true
    enable_statefulset_metrics = true
    enable_storage_metrics     = true
    # Kube state metrics collection requires Google Cloud Managed Service for Prometheus,
    # which is enabled by default.
    # enable_managed_prometheus = true
  }
}
# tftest modules=1 resources=1 inventory=monitoring-config-kube-state.yaml
```

The *control plane metrics* and *kube state metrics* collection can be configured in a single `monitoring_config` block.

## Backup for GKE

> [!NOTE]
> Although Backup for GKE can be enabled as an add-on when configuring your GKE clusters, it is a separate service from GKE.

[Backup for GKE](https://cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/concepts/backup-for-gke) is a service for backing up and restoring workloads in GKE clusters. It has two components:

- A [Google Cloud API](https://cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/reference/rest) that serves as the control plane for the service.
- A GKE add-on (the [Backup for GKE agent](https://cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/concepts/backup-for-gke#agent_overview)) that must be enabled in each cluster for which you wish to perform backup and restore operations.

Backup for GKE is supported in GKE Autopilot clusters with [some restrictions](https://cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/concepts/about-autopilot).

This example shows how to [enable Backup for GKE on a new Autopilot cluster](https://cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/how-to/install#enable_on_a_new_cluster_optional) and [plan a set of backups](https://cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/how-to/backup-plan).

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-autopilot"
  project_id = var.project_id
  name       = "cluster-1"
  location   = "europe-west1"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {}
  }
  backup_configs = {
    enable_backup_agent = true
    backup_plans = {
      "backup-1" = {
        region   = "europe-west-2"
        schedule = "0 9 * * 1"
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=backup.yaml
```

### Allowing access from Google Cloud services

To allow access to your cluster from Google Cloud services (like Cloud Shell, Cloud Build, etc.) without needing to manually specify all Google Cloud IP ranges, you can use the `gcp_public_cidrs_access_enabled` parameter:

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-autopilot"
  project_id = "myproject"
  name       = "cluster-1"
  location   = "europe-west1"
  access_config = {
    ip_access = {
      gcp_public_cidrs_access_enabled = true
      authorized_ranges = {
        internal-vms = "10.0.0.0/8"
      }
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }
  labels = {
    environment = "dev"
  }
}
# tftest modules=1 resources=1 inventory=access-google.yaml
```

### Disable PSC endpoint creation

To disable IP access to the GKE control plane and prevent PSC endpoint creation, set `var.access_config.ip_access` to `null` or omit the variable.

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-autopilot"
  project_id = "myproject"
  name       = "cluster-1"
  location   = "europe-west1"
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }
  labels = {
    environment = "dev"
  }
}
# tftest modules=1 resources=1 inventory=no-ip-access.yaml
```

## Upgrade notifications

Upgrade notifications are configured via the `enable_features.upgrade_notifications`. An existing PubSub topic can be defined via its `topic` attribute, or a new one can be created if the attribute is not set. The `event_types` attribute can be used to control which event types are sent. The `kms_key_name` attribute can be used to control which KMS key is used to encrypt the notification messages.

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-autopilot"
  project_id = var.project_id
  name       = "cluster-1"
  location   = "europe-west1"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {}
  }
  enable_features = {
    upgrade_notifications = {
      event_types  = ["SECURITY_BULLETIN_EVENT", "UPGRADE_EVENT"]
      kms_key_name = "projects/myproject/locations/global/keyRings/mykeyring/cryptoKeys/mykey"
    }
  }
}
# tftest modules=1 resources=2 inventory=notifications.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location](variables.tf#L186) | Autopilot clusters are always regional. | <code>string</code> | ✓ |  |
| [name](variables.tf#L269) | Cluster name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L302) | Cluster project ID. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L318) | VPC-level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [access_config](variables.tf#L17) | Control plane endpoint and nodes access configurations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [backup_configs](variables.tf#L49) | Configuration for Backup for GKE. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [deletion_protection](variables.tf#L71) | Whether or not to allow Terraform to destroy the cluster. Unless this field is set to false in Terraform state, a terraform destroy or terraform apply that would delete the cluster will fail. | <code>bool</code> |  | <code>true</code> |
| [description](variables.tf#L78) | Cluster description. | <code>string</code> |  | <code>null</code> |
| [enable_addons](variables.tf#L84) | Addons enabled in the cluster (true means enabled). | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [enable_features](variables.tf#L98) | Enable cluster-level features. Certain features allow configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [fleet_project](variables.tf#L168) | The name of the fleet host project where this cluster will be registered. | <code>string</code> |  | <code>null</code> |
| [issue_client_certificate](variables.tf#L174) | Enable issuing client certificate. | <code>bool</code> |  | <code>false</code> |
| [labels](variables.tf#L180) | Cluster resource labels. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [logging_config](variables.tf#L191) | Logging configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [maintenance_config](variables.tf#L202) | Maintenance window configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [min_master_version](variables.tf#L225) | Minimum version of the master, defaults to the version of the most recent official release. | <code>string</code> |  | <code>null</code> |
| [monitoring_config](variables.tf#L231) | Monitoring configuration. System metrics collection cannot be disabled. Control plane metrics are optional. Kube state metrics are optional. Google Cloud Managed Service for Prometheus is enabled by default. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [node_config](variables.tf#L274) | Configuration for nodes and nodepools. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [node_locations](variables.tf#L295) | Zones in which the cluster's nodes are located. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [release_channel](variables.tf#L307) | Release channel for GKE upgrades. Clusters created in the Autopilot mode must use a release channel. Choose between \"RAPID\", \"REGULAR\", and \"STABLE\". | <code>string</code> |  | <code>&#34;REGULAR&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [ca_certificate](outputs.tf#L17) | Public certificate of the cluster (base64-encoded). | ✓ |
| [cluster](outputs.tf#L23) | Cluster resource. | ✓ |
| [dns_endpoint](outputs.tf#L29) | Control plane DNS endpoint. |  |
| [endpoint](outputs.tf#L37) | Cluster endpoint. |  |
| [id](outputs.tf#L42) | Fully qualified cluster ID. |  |
| [location](outputs.tf#L47) | Cluster location. |  |
| [master_version](outputs.tf#L52) | Master version. |  |
| [name](outputs.tf#L57) | Cluster name. |  |
| [notifications](outputs.tf#L62) | GKE Pub/Sub notifications topic. |  |
| [self_link](outputs.tf#L67) | Cluster self link. | ✓ |
| [workload_identity_pool](outputs.tf#L73) | Workload identity pool. |  |
<!-- END TFDOC -->
