# GKE Multitenant Blueprint

This blueprint presents an opinionated architecture to handle multiple homogeneous GKE clusters. The general idea behind this blueprint is to deploy a single project hosting multiple clusters leveraging several useful GKE features.

The pattern used in this design is useful, for blueprint, in cases where multiple clusters host/support the same workloads, such as in the case of a multi-regional deployment. Furthermore, combined with Anthos Config Sync and proper RBAC, this architecture can be used to host multiple tenants (e.g. teams, applications) sharing the clusters.

This blueprint is used as part of the [FAST GKE stage](../../../fast/stages/03-gke-multitenant/) but it can also be used independently if desired.

<p align="center">
  <img src="diagram.png" alt="GKE multitenant">
</p>

The overall architecture is based on the following design decisions:

- All clusters are assumed to be [private](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters), therefore only [VPC-native clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips) are supported.
- Logging and monitoring configured to use Cloud Operations for system components and user workloads.
- [GKE metering](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-usage-metering) enabled by default and stored in a bigquery dataset created within the project.
- Optional [GKE Fleet](https://cloud.google.com/kubernetes-engine/docs/fleets-overview) support with the possibility to enable any of the following features:
  - [Fleet workload identity](https://cloud.google.com/anthos/fleet-management/docs/use-workload-identity)
  - [Anthos Config Management](https://cloud.google.com/anthos-config-management/docs/overview)
  - [Anthos Service Mesh](https://cloud.google.com/service-mesh/docs/overview)
  - [Anthos Identity Service](https://cloud.google.com/anthos/identity/setup/fleet)
  - [Multi-cluster services](https://cloud.google.com/kubernetes-engine/docs/concepts/multi-cluster-services)
  - [Multi-cluster ingress](https://cloud.google.com/kubernetes-engine/docs/concepts/multi-cluster-ingress).
- Support for [Config Sync](https://cloud.google.com/anthos-config-management/docs/config-sync-overview), [Hierarchy Controller](https://cloud.google.com/anthos-config-management/docs/concepts/hierarchy-controller), and [Policy Controller](https://cloud.google.com/anthos-config-management/docs/concepts/policy-controller) when using Anthos Config Management.
- [Groups for GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/google-groups-rbac) can be enabled to facilitate the creation of flexible RBAC policies referencing group principals.
- Support for [application layer secret encryption](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets).
- Support to customize peering configuration of the control plane VPC (e.g. to import/export routes to the peered network)
- Some features are enabled by default in all clusters:
  - [Intranode visibility](https://cloud.google.com/kubernetes-engine/docs/how-to/intranode-visibility)
  - [Dataplane v2](https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2)
  - [Shielded GKE nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/shielded-gke-nodes)
  - [Workload identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
  - [Node local DNS cache](https://cloud.google.com/kubernetes-engine/docs/how-to/nodelocal-dns-cache)
  - [Use of the GCE persistent disk CSI driver](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver)
  - Node [auto-upgrade](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades) and [auto-repair](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair) for all node pools

<!--
- [GKE subsetting for L4 internal load balancers](https://cloud.google.com/kubernetes-engine/docs/concepts/service-load-balancer#subsetting) enabled by default in all clusters
-->

## Basic usage

The following example shows how to deploy a single cluster and a single node pool

```hcl
module "gke" {
  source             = "./fabric/blueprints/gke/multitenant-fleet/"
  project_id         = var.project_id
  billing_account_id = var.billing_account_id
  folder_id          = var.folder_id
  prefix             = "myprefix"
  vpc_config = {
    host_project_id = "my-host-project-id"
    vpc_self_link   = "projects/my-host-project-id/global/networks/my-network"
  }

  authenticator_security_group = "gke-rbac-base@example.com"
  group_iam = {
    "gke-admin@example.com" = [
      "roles/container.admin"
    ]
  }
  iam = {
    "roles/container.clusterAdmin" = [
      "cicd@my-cicd-project.iam.gserviceaccount.com"
    ]
  }

  clusters = {
    mycluster = {
      cluster_autoscaling = null
      description         = "My cluster"
      dns_domain          = null
      location            = "europe-west1"
      labels              = {}
      net = {
        master_range = "172.17.16.0/28"
        pods         = "pods"
        services     = "services"
        subnet       = "projects/my-host-project-id/regions/europe-west1/subnetworks/mycluster-subnet"
      }
      overrides = null
    }
  }
  nodepools = {
    mycluster = {
      mynodepool = {
        initial_node_count = 1
        node_count         = 1
        node_type          = "n2-standard-4"
        overrides          = null
        spot               = false
      }
    }
  }
}
# tftest modules=1 resources=0
```

## Creating Multiple Clusters

The following example shows how to deploy two clusters with different configurations.

The first cluster `cluster-euw1` defines the mandatory configuration parameters (description, location, network setup) and inherits the some defaults from the `cluster_defaults` and `nodepool_deaults` variables. These two variables are used whenever the `override` key of the `clusters` and `nodepools` variables are set to `null`.

On the other hand, the second cluster (`cluster-euw3`) defines its own configuration by providing a value to the `overrides` key.

```hcl
module "gke" {
  source             = "./fabric/blueprints/gke/multitenant-fleet/"
  project_id         = var.project_id
  billing_account_id = var.billing_account_id
  folder_id          = var.folder_id
  prefix             = "myprefix"
  vpc_config = {
    host_project_id = "my-host-project-id"
    vpc_self_link   = "projects/my-host-project-id/global/networks/my-network"
  }
  clusters = {
    cluster-euw1 = {
      cluster_autoscaling = null
      description         = "Cluster for europ-west1"
      dns_domain          = null
      location            = "europe-west1"
      labels              = {}
      net = {
        master_range = "172.17.16.0/28"
        pods         = "pods"
        services     = "services"
        subnet       = "projects/my-host-project-id/regions/europe-west1/subnetworks/euw1-subnet"
      }
      overrides = null
    }
    cluster-euw3 = {
      cluster_autoscaling = null
      description         = "Cluster for europe-west3"
      dns_domain          = null
      location            = "europe-west3"
      labels              = {}
      net = {
        master_range = "172.17.17.0/28"
        pods         = "pods"
        services     = "services"
        subnet       = "projects/my-host-project-id/regions/europe-west3/subnetworks/euw3-subnet"
      }
      overrides = {
        cloudrun_config                 = false
        database_encryption_key         = null
        gcp_filestore_csi_driver_config = true
        master_authorized_ranges = {
          rfc1918_1 = "10.0.0.0/8"
        }
        max_pods_per_node        = 64
        pod_security_policy      = true
        release_channel          = "STABLE"
        vertical_pod_autoscaling = false
      }
    }
  }
  nodepools = {
    cluster-euw1 = {
      pool-euw1 = {
        initial_node_count = 1
        node_count         = 1
        node_type          = "n2-standard-4"
        overrides          = null
        spot               = false
      }
    }
    cluster-euw3 = {
      pool-euw3 = {
        initial_node_count = 1
        node_count         = 1
        node_type          = "n2-standard-4"
        overrides = {
          image_type        = "UBUNTU_CONTAINERD"
          max_pods_per_node = 64
          node_locations    = []
          node_tags         = []
          node_taints       = []
        }
        spot = true
      }
    }
  }
}
# tftest modules=1 resources=0
```

## Multiple clusters with GKE Fleet

This example deploys two clusters and configures several GKE Fleet features:

- Enables [multi-cluster ingress](https://cloud.google.com/kubernetes-engine/docs/concepts/multi-cluster-ingress) and sets the configuration cluster to be `cluster-eu1`.
- Enables [Multi-cluster services](https://cloud.google.com/kubernetes-engine/docs/concepts/multi-cluster-services) and assigns the [required roles](https://cloud.google.com/kubernetes-engine/docs/how-to/multi-cluster-services#authenticating) to its service accounts.
- A `default` Config Management template is created with binary authorization, config sync enabled with a git repository, hierarchy controller, and policy controller.
- The two clusters are configured to use the `default` Config Management template.

```hcl
module "gke" {
  source             = "./fabric/blueprints/gke/multitenant-fleet/"
  project_id         = var.project_id
  billing_account_id = var.billing_account_id
  folder_id          = var.folder_id
  prefix             = "myprefix"
  vpc_config = {
    host_project_id = "my-host-project-id"
    vpc_self_link   = "projects/my-host-project-id/global/networks/my-network"
  }
  clusters = {
    cluster-euw1 = {
      cluster_autoscaling = null
      description         = "Cluster for europe-west1"
      dns_domain          = null
      location            = "europe-west1"
      labels              = {}
      net = {
        master_range = "172.17.16.0/28"
        pods         = "pods"
        services     = "services"
        subnet       = "projects/my-host-project-id/regions/europe-west1/subnetworks/euw1-subnet"
      }
      overrides = null
    }
    cluster-euw3 = {
      cluster_autoscaling = null
      description         = "Cluster for europe-west3"
      dns_domain          = null
      location            = "europe-west3"
      labels              = {}
      net = {
        master_range = "172.17.17.0/28"
        pods         = "pods"
        services     = "services"
        subnet       = "projects/my-host-project-id/regions/europe-west3/subnetworks/euw3-subnet"
      }
      overrides = null
    }
  }
  nodepools = {
    cluster-euw1 = {
      pool-euw1 = {
        initial_node_count = 1
        node_count         = 1
        node_type          = "n2-standard-4"
        overrides          = null
        spot               = false
      }
    }
    cluster-euw3 = {
      pool-euw3 = {
        initial_node_count = 1
        node_count         = 1
        node_type          = "n2-standard-4"
        overrides          = null
        spot               = true
      }
    }
  }

  fleet_features = {
    appdevexperience             = false
    configmanagement             = true
    identityservice              = true
    multiclusteringress          = "cluster-euw1"
    multiclusterservicediscovery = true
    servicemesh                  = true
  }
  fleet_workload_identity = true
  fleet_configmanagement_templates = {
    default = {
      binauthz = true
      config_sync = {
        git = {
          gcp_service_account_email = null
          https_proxy               = null
          policy_dir                = "configsync"
          secret_type               = "none"
          source_format             = "hierarchy"
          sync_branch               = "main"
          sync_repo                 = "https://github.com/myorg/myrepo"
          sync_rev                  = null
          sync_wait_secs            = null
        }
        prevent_drift = true
        source_format = "hierarchy"
      }
      hierarchy_controller = {
        enable_hierarchical_resource_quota = true
        enable_pod_tree_labels             = true
      }
      policy_controller    = {
        audit_interval_seconds     = 30
        exemptable_namespaces      = ["kube-system"]
        log_denies_enabled         = true
        referential_rules_enabled  = true
        template_library_installed = true
      }
      version              = "1.10.2"
    }
  }
  fleet_configmanagement_clusters = {
    default = ["cluster-euw1", "cluster-euw3"]
  }
}

# tftest modules=1 resources=0
```

<!-- TFDOC OPTS files:1 show_extra:1 -->
<!-- BEGIN TFDOC -->

## Files

| name | description | modules |
|---|---|---|
| [gke-clusters.tf](./gke-clusters.tf) | None | <code>gke-cluster</code> |
| [gke-hub.tf](./gke-hub.tf) | None | <code>gke-hub</code> |
| [gke-nodepools.tf](./gke-nodepools.tf) | None | <code>gke-nodepool</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>bigquery-dataset</code> · <code>project</code> |
| [outputs.tf](./outputs.tf) | Output variables. |  |
| [variables.tf](./variables.tf) | Module variables. |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [billing_account_id](variables.tf#L23) | Billing account id. | <code>string</code> | ✓ |  |  |
| [clusters](variables.tf#L57) |  | <code title="map&#40;object&#40;&#123;&#10;  cluster_autoscaling &#61; object&#40;&#123;&#10;    cpu_min    &#61; number&#10;    cpu_max    &#61; number&#10;    memory_min &#61; number&#10;    memory_max &#61; number&#10;  &#125;&#41;&#10;  description &#61; string&#10;  dns_domain  &#61; string&#10;  labels      &#61; map&#40;string&#41;&#10;  location    &#61; string&#10;  net &#61; object&#40;&#123;&#10;    master_range &#61; string&#10;    pods         &#61; string&#10;    services     &#61; string&#10;    subnet       &#61; string&#10;  &#125;&#41;&#10;  overrides &#61; object&#40;&#123;&#10;    cloudrun_config         &#61; bool&#10;    database_encryption_key &#61; string&#10;    master_authorized_ranges        &#61; map&#40;string&#41;&#10;    max_pods_per_node               &#61; number&#10;    pod_security_policy             &#61; bool&#10;    release_channel                 &#61; string&#10;    vertical_pod_autoscaling        &#61; bool&#10;    gcp_filestore_csi_driver_config &#61; bool&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |  |
| [folder_id](variables.tf#L158) | Folder used for the GKE project in folders/nnnnnnnnnnn format. | <code>string</code> | ✓ |  |  |
| [nodepools](variables.tf#L201) |  | <code title="map&#40;map&#40;object&#40;&#123;&#10;  node_count         &#61; number&#10;  node_type          &#61; string&#10;  initial_node_count &#61; number&#10;  overrides &#61; object&#40;&#123;&#10;    image_type        &#61; string&#10;    max_pods_per_node &#61; number&#10;    node_locations    &#61; list&#40;string&#41;&#10;    node_tags         &#61; list&#40;string&#41;&#10;    node_taints       &#61; list&#40;string&#41;&#10;  &#125;&#41;&#10;  spot &#61; bool&#10;&#125;&#41;&#41;&#41;">map&#40;map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;&#41;</code> | ✓ |  |  |
| [prefix](variables.tf#L231) | Prefix used for resources that need unique names. | <code>string</code> | ✓ |  |  |
| [project_id](variables.tf#L236) | ID of the project that will contain all the clusters. | <code>string</code> | ✓ |  |  |
| [vpc_config](variables.tf#L248) | Shared VPC project and VPC details. | <code title="object&#40;&#123;&#10;  host_project_id &#61; string&#10;  vpc_self_link   &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [authenticator_security_group](variables.tf#L17) | Optional group used for Groups for GKE. | <code>string</code> |  | <code>null</code> |  |
| [cluster_defaults](variables.tf#L28) | Default values for optional cluster configurations. | <code title="object&#40;&#123;&#10;  cloudrun_config                 &#61; bool&#10;  database_encryption_key         &#61; string&#10;  master_authorized_ranges        &#61; map&#40;string&#41;&#10;  max_pods_per_node               &#61; number&#10;  pod_security_policy             &#61; bool&#10;  release_channel                 &#61; string&#10;  vertical_pod_autoscaling        &#61; bool&#10;  gcp_filestore_csi_driver_config &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  cloudrun_config         &#61; false&#10;  database_encryption_key &#61; null&#10;  master_authorized_ranges &#61; &#123;&#10;    rfc1918_1 &#61; &#34;10.0.0.0&#47;8&#34;&#10;    rfc1918_2 &#61; &#34;172.16.0.0&#47;12&#34;&#10;    rfc1918_3 &#61; &#34;192.168.0.0&#47;16&#34;&#10;  &#125;&#10;  max_pods_per_node               &#61; 110&#10;  pod_security_policy             &#61; false&#10;  release_channel                 &#61; &#34;STABLE&#34;&#10;  vertical_pod_autoscaling        &#61; false&#10;  gcp_filestore_csi_driver_config &#61; false&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [dns_domain](variables.tf#L90) | Domain name used for clusters, prefixed by each cluster name. Leave null to disable Cloud DNS for GKE. | <code>string</code> |  | <code>null</code> |  |
| [fleet_configmanagement_clusters](variables.tf#L96) | Config management features enabled on specific sets of member clusters, in config name => [cluster name] format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [fleet_configmanagement_templates](variables.tf#L103) | Sets of config management configurations that can be applied to member clusters, in config name => {options} format. | <code title="map&#40;object&#40;&#123;&#10;  binauthz &#61; bool&#10;  config_sync &#61; object&#40;&#123;&#10;    git &#61; object&#40;&#123;&#10;      gcp_service_account_email &#61; string&#10;      https_proxy               &#61; string&#10;      policy_dir                &#61; string&#10;      secret_type               &#61; string&#10;      sync_branch               &#61; string&#10;      sync_repo                 &#61; string&#10;      sync_rev                  &#61; string&#10;      sync_wait_secs            &#61; number&#10;    &#125;&#41;&#10;    prevent_drift &#61; string&#10;    source_format &#61; string&#10;  &#125;&#41;&#10;  hierarchy_controller &#61; object&#40;&#123;&#10;    enable_hierarchical_resource_quota &#61; bool&#10;    enable_pod_tree_labels             &#61; bool&#10;  &#125;&#41;&#10;  policy_controller &#61; object&#40;&#123;&#10;    audit_interval_seconds     &#61; number&#10;    exemptable_namespaces      &#61; list&#40;string&#41;&#10;    log_denies_enabled         &#61; bool&#10;    referential_rules_enabled  &#61; bool&#10;    template_library_installed &#61; bool&#10;  &#125;&#41;&#10;  version &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [fleet_features](variables.tf#L138) | Enable and configue fleet features. Set to null to disable GKE Hub if fleet workload identity is not used. | <code title="object&#40;&#123;&#10;  appdevexperience             &#61; bool&#10;  configmanagement             &#61; bool&#10;  identityservice              &#61; bool&#10;  multiclusteringress          &#61; string&#10;  multiclusterservicediscovery &#61; bool&#10;  servicemesh                  &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |  |
| [fleet_workload_identity](variables.tf#L151) | Use Fleet Workload Identity for clusters. Enables GKE Hub if set to true. | <code>bool</code> |  | <code>false</code> |  |
| [group_iam](variables.tf#L163) | Project-level IAM bindings for groups. Use group emails as keys, list of roles as values. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [iam](variables.tf#L170) | Project-level authoritative IAM bindings for users and service accounts in  {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [labels](variables.tf#L177) | Project-level labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [nodepool_defaults](variables.tf#L183) |  | <code title="object&#40;&#123;&#10;  image_type        &#61; string&#10;  max_pods_per_node &#61; number&#10;  node_locations    &#61; list&#40;string&#41;&#10;  node_tags         &#61; list&#40;string&#41;&#10;  node_taints       &#61; list&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  image_type        &#61; &#34;COS_CONTAINERD&#34;&#10;  max_pods_per_node &#61; 110&#10;  node_locations    &#61; null&#10;  node_tags         &#61; null&#10;  node_taints       &#61; &#91;&#93;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [peering_config](variables.tf#L218) | Configure peering with the control plane VPC. Requires compute.networks.updatePeering. Set to null if you don't want to update the default peering configuration. | <code title="object&#40;&#123;&#10;  export_routes &#61; bool&#10;  import_routes &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  export_routes &#61; true&#10;  &#47;&#47; TODO&#40;jccb&#41; is there any situation where the control plane VPC would export any routes&#63;&#10;  import_routes &#61; false&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [project_services](variables.tf#L241) | Additional project services to enable. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [cluster_ids](outputs.tf#L22) | Cluster ids. |  |  |
| [clusters](outputs.tf#L17) | Cluster resources. |  |  |
| [project_id](outputs.tf#L29) | GKE project id. |  |  |

<!-- END TFDOC -->
