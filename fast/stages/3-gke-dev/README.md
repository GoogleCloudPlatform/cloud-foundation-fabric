# GKE Multitenant

This stage allows creation and management of a fleet of GKE multitenant clusters for a single environment, optionally leveraging GKE Hub to configure additional features.

The following diagram illustrates the high-level design of created resources, which can be adapted to specific requirements via variables:

<p align="center">
  <img src="diagram.png" alt="GKE multitenant">
</p>

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
- [How to run this stage](#how-to-run-this-stage)
  - [FAST prerequisites](#fast-prerequisites)
- [Customizations](#customizations)
  - [Clusters and node pools](#clusters-and-node-pools)
  - [Fleet management](#fleet-management)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Design overview and choices

The general idea behind this stage is to deploy a single project hosting multiple clusters leveraging several useful GKE features like Config Sync, which lend themselves well to a multitenant approach to GKE.

Some high level choices applied here:

- all clusters are created as [private clusters](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters) which then need to be [VPC-native](https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips).
- Logging and monitoring uses Cloud Operations for system components and user workloads.
- [GKE metering](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-usage-metering) is enabled by default and stored in a BigQuery dataset created within the project.
- [GKE Fleet](https://cloud.google.com/kubernetes-engine/docs/fleets-overview) can be optionally with support for the following features:
  - [Fleet workload identity](https://cloud.google.com/anthos/fleet-management/docs/use-workload-identity)
  - [Config Management](https://cloud.google.com/anthos-config-management/docs/overview)
  - [Service Mesh](https://cloud.google.com/service-mesh/docs/overview)
  - [Identity Service](https://cloud.google.com/anthos/identity/setup/fleet)
  - [Multi-cluster services](https://cloud.google.com/kubernetes-engine/docs/concepts/multi-cluster-services)
  - [Multi-cluster ingress](https://cloud.google.com/kubernetes-engine/docs/concepts/multi-cluster-ingress).
- Support for [Config Sync](https://cloud.google.com/anthos-config-management/docs/config-sync-overview) and [Hierarchy Controller](https://cloud.google.com/anthos-config-management/docs/concepts/hierarchy-controller) when using Config Management.
- [Groups for GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/google-groups-rbac) can be enabled to facilitate the creation of flexible RBAC policies referencing group principals.
- Support for [application layer secret encryption](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets).
- Some features are enabled by default in all clusters:
  - [Intranode visibility](https://cloud.google.com/kubernetes-engine/docs/how-to/intranode-visibility)
  - [Dataplane v2](https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2)
  - [Shielded GKE nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/shielded-gke-nodes)
  - [Workload identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
  - [Node local DNS cache](https://cloud.google.com/kubernetes-engine/docs/how-to/nodelocal-dns-cache)
  - [Use of the GCE persistent disk CSI driver](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver)
  - Node [auto-upgrade](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades) and [auto-repair](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair) for all node pools

## How to run this stage

If this stage is deployed within a FAST-based GCP organization, we recommend executing it after foundational FAST `stage-2` components like `networking` and `security`. This is the recommended flow as specific data platform features in this stage might depend on configurations from these earlier stages. Although this stage can be run independently, instructions for such a standalone setup are beyond the scope of this document.

### FAST prerequisites

This stage needs specific automation resources, and permissions granted on those that allow control of selective IAM roles on specific networking and security resources.

Network permissions are needed to associate data domain or product projects to Shared VPC hosts and grant network permissions to data platform managed service accounts. They are mandatory when deploying Composer.

Security permissions are only needed when using CMEK encryption, to grant the relevant IAM roles to data platform service agents on the encryption keys used.

The ["Classic FAST" dataset](../0-org-setup/README.md#classic-fast-dataset) in the bootstrap stage contains the configuration for a development Data Platform that can be easily adapted to serve for this stage.

## Customizations

This stage is designed with multi-tenancy in mind, and the expectation is that  GKE clusters will mostly share a common set of defaults. Variables allow management of clusters, nodepools, and fleet registration and configurations.

### Clusters and node pools

This is an example of declaring a private cluster with one nodepool via `tfvars` file:

```hcl
clusters = {
  test-00 = {
    description = "Cluster test 0"
    location    = "europe-west8"
    private_cluster_config = {
      enable_private_endpoint = true
      master_global_access    = true
    }
    vpc_config = {
      subnetwork             = "projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gke"
      master_ipv4_cidr_block = "172.16.20.0/28"
      master_authorized_ranges = {
        private = "10.0.0.0/8"
      }
    }
  }
}
nodepools = {
  test-00 = {
    00 = {
      node_count = { initial = 1 }
    }
  }
}
# tftest skip
```

And here another example of declaring a private cluster following hardening guidelines with one nodepool via `tfvars` file:
```hcl
clusters = {
  test-00 = {
    description = "Hardened Cluster test 0"
    location    = "europe-west1"
    private_cluster_config = {
      enable_private_endpoint = true
      master_global_access    = true
    }
    access_config = {
      dns_access = true
      ip_access = {
        disable_public_endpoint = true
      }
      private_nodes = true
    }
    enable_features =  {
      binary_authorization = true
      groups_for_rbac      = "gke-security-groups@example.com"
      intranode_visibility = true
      rbac_binding_config = {
        enable_insecure_binding_system_unauthenticated: false
        enable_insecure_binding_system_authenticated: false
      }
      shielded_nodes       = true
      upgrade_notifications = {
        event_types = ["SECURITY_BULLETIN_EVENT", "UPGRADE_AVAILABLE_EVENT", "UPGRADE_INFO_EVENT", "UPGRADE_EVENT"]
      }
      workload_identity    = true
    }
    vpc_config = {
      subnetwork             = "projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gke"
      master_ipv4_cidr_block = "172.16.20.0/28"
      master_authorized_ranges = {
        private = "10.0.0.0/8"
      }
    }
  }
}
nodepools = {
  test-00 = {
    00 = {
      node_count  = { initial = 1 }
      node_config = {
        sandbox_config_gvisor = true
      }
    }
  }
}
# tftest skip
```


If clusters share similar configurations, those can be centralized via `locals` blocks in this stage's `main.tf` file, and merged in with clusters via a simple `for_each` loop.

### Fleet management

Fleet management is entirely optional, and uses two separate variables:

- `fleet_config`: specifies the [GKE fleet](https://cloud.google.com/anthos/fleet-management/docs/fleet-concepts#fleet-enabled-components) features to activate
- `fleet_configmanagement_templates`: defines configuration templates for specific sets of features ([Config Management](https://cloud.google.com/anthos-config-management/docs/how-to/install-anthos-config-management) currently)

Clusters can then be configured for fleet registration and one of the config management templates attached via the cluster-level `fleet_config` attribute.

<!-- TFDOC OPTS files:1 show_extra:1 exclude:3-gke-dev-providers.tf -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [gke-clusters.tf](./gke-clusters.tf) | GKE clusters. | <code>gke-cluster-standard</code> · <code>gke-nodepool</code> |  |
| [gke-hub.tf](./gke-hub.tf) | GKE hub configuration. | <code>gke-hub</code> |  |
| [main.tf](./main.tf) | Project and usage dataset. | <code>bigquery-dataset</code> · <code>iam-service-account</code> · <code>project</code> |  |
| [outputs.tf](./outputs.tf) | Module outputs. |  | <code>google_storage_bucket_object</code> |
| [variables-fast.tf](./variables-fast.tf) | None |  |  |
| [variables-fleet.tf](./variables-fleet.tf) | GKE fleet configurations. |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [automation](variables-fast.tf#L17) | Automation resources created by the bootstrap stage. | <code title="object&#40;&#123;&#10;  outputs_bucket &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-org-setup</code> |
| [billing_account](variables-fast.tf#L26) | Billing account id. If billing account is not part of the same org set `is_org_level` to false. | <code title="object&#40;&#123;&#10;  id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-org-setup</code> |
| [environments](variables-fast.tf#L34) | Long environment names. | <code title="object&#40;&#123;&#10;  dev &#61; object&#40;&#123;&#10;    name &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>1-resman</code> |
| [prefix](variables-fast.tf#L60) | Prefix used for resources that need unique names. Use a maximum of 9 chars for organizations, and 11 chars for tenants. | <code>string</code> | ✓ |  | <code>0-org-setup</code> |
| [clusters](variables.tf#L17) | Clusters configuration. Refer to the gke-cluster module for type details. | <code title="map&#40;object&#40;&#123;&#10;  access_config &#61; optional&#40;object&#40;&#123;&#10;    dns_access &#61; optional&#40;bool, true&#41;&#10;    ip_access &#61; optional&#40;object&#40;&#123;&#10;      authorized_ranges               &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;      disable_public_endpoint         &#61; optional&#40;bool, true&#41;&#10;      gcp_public_cidrs_access_enabled &#61; optional&#40;bool, false&#41;&#10;      private_endpoint_config &#61; optional&#40;object&#40;&#123;&#10;        endpoint_subnetwork &#61; optional&#40;string&#41;&#10;        global_access       &#61; optional&#40;bool, true&#41;&#10;      &#125;&#41;, &#123;&#125;&#41;&#10;    &#125;&#41;&#41;&#10;    private_nodes &#61; optional&#40;bool, true&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  cluster_autoscaling &#61; optional&#40;any&#41;&#10;  description         &#61; optional&#40;string&#41;&#10;  enable_addons &#61; optional&#40;any, &#123;&#10;    horizontal_pod_autoscaling &#61; true, http_load_balancing &#61; true&#10;  &#125;&#41;&#10;  enable_features &#61; optional&#40;any, &#123;&#10;    shielded_nodes    &#61; true&#10;    workload_identity &#61; true&#10;  &#125;&#41;&#10;  fleet_config &#61; optional&#40;object&#40;&#123;&#10;    register                  &#61; optional&#40;bool, true&#41;&#10;    configmanagement_template &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  issue_client_certificate &#61; optional&#40;bool, false&#41;&#10;  labels                   &#61; optional&#40;map&#40;string&#41;&#41;&#10;  location                 &#61; string&#10;  logging_config &#61; optional&#40;object&#40;&#123;&#10;    enable_system_logs             &#61; optional&#40;bool, true&#41;&#10;    enable_workloads_logs          &#61; optional&#40;bool, true&#41;&#10;    enable_api_server_logs         &#61; optional&#40;bool, false&#41;&#10;    enable_scheduler_logs          &#61; optional&#40;bool, false&#41;&#10;    enable_controller_manager_logs &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  maintenance_config &#61; optional&#40;any, &#123;&#10;    daily_window_start_time &#61; &#34;03:00&#34;&#10;    recurring_window        &#61; null&#10;    maintenance_exclusion   &#61; &#91;&#93;&#10;  &#125;&#41;&#10;  max_pods_per_node  &#61; optional&#40;number, 110&#41;&#10;  min_master_version &#61; optional&#40;string&#41;&#10;  monitoring_config &#61; optional&#40;object&#40;&#123;&#10;    enable_system_metrics &#61; optional&#40;bool, true&#41;&#10;    enable_api_server_metrics         &#61; optional&#40;bool, false&#41;&#10;    enable_controller_manager_metrics &#61; optional&#40;bool, false&#41;&#10;    enable_scheduler_metrics          &#61; optional&#40;bool, false&#41;&#10;    enable_daemonset_metrics   &#61; optional&#40;bool, false&#41;&#10;    enable_deployment_metrics  &#61; optional&#40;bool, false&#41;&#10;    enable_hpa_metrics         &#61; optional&#40;bool, false&#41;&#10;    enable_pod_metrics         &#61; optional&#40;bool, false&#41;&#10;    enable_statefulset_metrics &#61; optional&#40;bool, false&#41;&#10;    enable_storage_metrics     &#61; optional&#40;bool, false&#41;&#10;    enable_managed_prometheus &#61; optional&#40;bool, true&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  node_locations  &#61; optional&#40;list&#40;string&#41;&#41;&#10;  release_channel &#61; optional&#40;string&#41;&#10;  service_account &#61; optional&#40;string&#41;&#10;  vpc_config &#61; object&#40;&#123;&#10;    subnetwork &#61; string&#10;    network    &#61; optional&#40;string&#41;&#10;    secondary_range_blocks &#61; optional&#40;object&#40;&#123;&#10;      pods     &#61; string&#10;      services &#61; string&#10;    &#125;&#41;&#41;&#10;    secondary_range_names &#61; optional&#40;object&#40;&#123;&#10;      pods     &#61; string&#10;      services &#61; string&#10;    &#125;&#41;, &#123; pods &#61; &#34;pods&#34;, services &#61; &#34;services&#34; &#125;&#41;&#10;  &#125;&#41;&#10;  node_config &#61; optional&#40;object&#40;&#123;&#10;    boot_disk_kms_key &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [deletion_protection](variables.tf#L102) | Prevent Terraform from destroying data resources. | <code>bool</code> |  | <code>false</code> |  |
| [fleet_config](variables-fleet.tf#L19) | Fleet configuration. | <code title="object&#40;&#123;&#10;  enable_features &#61; optional&#40;object&#40;&#123;&#10;    appdevexperience             &#61; optional&#40;bool, false&#41;&#10;    configmanagement             &#61; optional&#40;bool, false&#41;&#10;    identityservice              &#61; optional&#40;bool, false&#41;&#10;    multiclusteringress          &#61; optional&#40;string, null&#41;&#10;    multiclusterservicediscovery &#61; optional&#40;bool, false&#41;&#10;    servicemesh                  &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  use_workload_identity &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |  |
| [fleet_configmanagement_templates](variables-fleet.tf#L35) | Sets of fleet configurations that can be applied to member clusters, in config name => {options} format. | <code title="map&#40;object&#40;&#123;&#10;  binauthz &#61; optional&#40;bool&#41;&#10;  version  &#61; optional&#40;string&#41;&#10;  config_sync &#61; object&#40;&#123;&#10;    git &#61; optional&#40;object&#40;&#123;&#10;      sync_repo                 &#61; string&#10;      policy_dir                &#61; string&#10;      gcp_service_account_email &#61; optional&#40;string&#41;&#10;      https_proxy               &#61; optional&#40;string&#41;&#10;      secret_type               &#61; optional&#40;string, &#34;none&#34;&#41;&#10;      sync_branch               &#61; optional&#40;string&#41;&#10;      sync_rev                  &#61; optional&#40;string&#41;&#10;      sync_wait_secs            &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    prevent_drift &#61; optional&#40;bool&#41;&#10;    source_format &#61; optional&#40;string, &#34;hierarchy&#34;&#41;&#10;  &#125;&#41;&#10;  hierarchy_controller &#61; optional&#40;object&#40;&#123;&#10;    enable_hierarchical_resource_quota &#61; optional&#40;bool&#41;&#10;    enable_pod_tree_labels             &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  policy_controller &#61; object&#40;&#123;&#10;    audit_interval_seconds     &#61; optional&#40;number&#41;&#10;    exemptable_namespaces      &#61; optional&#40;list&#40;string&#41;&#41;&#10;    log_denies_enabled         &#61; optional&#40;bool&#41;&#10;    referential_rules_enabled  &#61; optional&#40;bool&#41;&#10;    template_library_installed &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [folder_ids](variables-fast.tf#L44) | Folder name => id mappings. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>1-resman</code> |
| [host_project_ids](variables-fast.tf#L52) | Shared VPC host project name => id mappings. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
| [iam](variables.tf#L109) | Project-level authoritative IAM bindings for users and service accounts in  {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [iam_by_principals](variables.tf#L116) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [nodepools](variables.tf#L123) | Nodepools configuration. Refer to the gke-nodepool module for type details. | <code title="map&#40;map&#40;object&#40;&#123;&#10;  gke_version       &#61; optional&#40;string&#41;&#10;  k8s_labels        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  max_pods_per_node &#61; optional&#40;number&#41;&#10;  name              &#61; optional&#40;string&#41;&#10;  node_config &#61; optional&#40;any, &#123;&#10;    disk_type &#61; &#34;pd-balanced&#34;&#10;    shielded_instance_config &#61; &#123;&#10;      enable_integrity_monitoring &#61; true&#10;      enable_secure_boot          &#61; true&#10;    &#125;&#10;  &#125;&#41;&#10;  node_count &#61; optional&#40;map&#40;number&#41;, &#123;&#10;    initial &#61; 1&#10;  &#125;&#41;&#10;  node_locations  &#61; optional&#40;list&#40;string&#41;&#41;&#10;  nodepool_config &#61; optional&#40;any&#41;&#10;  network_config &#61; optional&#40;object&#40;&#123;&#10;    enable_private_nodes &#61; optional&#40;bool, true&#41;&#10;    pod_range &#61; optional&#40;object&#40;&#123;&#10;      cidr   &#61; optional&#40;string&#41;&#10;      create &#61; optional&#40;bool, false&#41;&#10;      name   &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    additional_node_network_configs &#61; optional&#40;list&#40;object&#40;&#123;&#10;      network    &#61; string&#10;      subnetwork &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    additional_pod_network_configs &#61; optional&#40;list&#40;object&#40;&#123;&#10;      subnetwork          &#61; string&#10;      secondary_pod_range &#61; string&#10;      max_pods_per_node   &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;  reservation_affinity  &#61; optional&#40;any&#41;&#10;  service_account       &#61; optional&#40;any&#41;&#10;  sole_tenant_nodegroup &#61; optional&#40;string&#41;&#10;  tags                  &#61; optional&#40;list&#40;string&#41;&#41;&#10;  taints &#61; optional&#40;map&#40;object&#40;&#123;&#10;    value  &#61; string&#10;    effect &#61; string&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;&#41;&#41;">map&#40;map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [stage_config](variables.tf#L172) | FAST stage configuration used to find resource ids. Must match name defined for the stage in resource management. | <code title="object&#40;&#123;&#10;  environment &#61; string&#10;  name        &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  environment &#61; &#34;dev&#34;&#10;  name        &#61; &#34;gke-dev&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [subnet_self_links](variables-fast.tf#L70) | Subnet VPC name => { name => self link }  mappings. | <code>map&#40;map&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
| [vpc_config](variables.tf#L184) | VPC-level configuration for project and clusters. | <code title="object&#40;&#123;&#10;  host_project_id &#61; string&#10;  vpc_self_link   &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  host_project_id &#61; &#34;dev-spoke-0&#34;&#10;  vpc_self_link   &#61; &#34;dev-spoke-0&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [vpc_self_links](variables-fast.tf#L78) | Shared VPC name => self link mappings. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [cluster_ids](outputs.tf#L15) | Cluster ids. |  |  |
| [clusters](outputs.tf#L22) | Cluster resources. | ✓ |  |
| [project_id](outputs.tf#L28) | GKE project id. |  |  |
<!-- END TFDOC -->
