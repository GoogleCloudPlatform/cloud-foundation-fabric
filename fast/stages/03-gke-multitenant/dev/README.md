# GKE Multitenant

TODO: add description and diagram

<p align="center">
  <img src="diagram.png" alt="GKE multitenant">
</p>

## Design overview and choices

TODO

### Cluster and nodepool configuration

Clusters and nodepools configuration comes with variables that let you define common configuration (cluster_default) and define the single cluster details when needed. This stage is designed with multi-tenancy in mind, this means that the GKE clusters within this stage will be similar more often than not.

```
cluster_defaults = {
  cloudrun_config                 = false
  database_encryption_key         = null
  gcp_filestore_csi_driver_config = false
  master_authorized_ranges = {
    rfc1918_1 = "10.0.0.0/8"
    rfc1918_2 = "172.16.0.0/12"
    rfc1918_3 = "192.168.0.0/16"
    on_prem = "100.xxx.xxx.xxx/xx"
  }
  max_pods_per_node        = 110
  pod_security_policy      = false
  release_channel          = "STABLE"
  vertical_pod_autoscaling = false
}
```
The variable cluster_defaults is used as a shared configuration between all the clusters within the projects, clusters variable instead can be used to define the required specific details:

```
clusters = {
  "gke-1" = {
    cluster_autoscaling = null
    description         = "gke-1"
    dns_domain          = null
    location            = "europe-west1"
    labels              = {}
    net = {
      master_range = "172.17.16.0/28"
      pods         = "pods"
      services     = "services"
      subnet       = "https://www.googleapis.com/compute/v1/projects/XXXX-dev-net-spoke-0/regions/europe-west1/subnetworks/dev-gke-nodes-ew1"
    }
    overrides = null
  }
  "gke-2" = {
    cluster_autoscaling = null
    description         = "gke-2"
    dns_domain          = null
    location            = "europe-west3"
    labels              = {}
    net = {
      master_range = "172.17.17.0/28"
      pods         = "pods"
      services     = "services"
      subnet       = "https://www.googleapis.com/compute/v1/projects/XXXX-dev-net-spoke-0/regions/europe-west3/subnetworks/dev-gke-nodes-ew3"
    }
    overrides = null
  }
}

```
The same design principle used for the clusters variable is used to define the nodepool and attach them to the right GKE cluster (previously defined)

```
nodepools = {
  "gke-1" = {
    "np-001" = {
      initial_node_count = 1
      node_count         = 1
      node_type          = "n2-standard-4"
      overrides          = null
      spot               = false
    }
  }
  "gke-2" = {
    "np-002" = {
      initial_node_count = 1
      node_count         = 1
      node_type          = "n2-standard-4"
      overrides          = null
      spot               = true
    }
  }
}
```

On the top of all the clusters configuration, the variable authenticator_security_group can be used to define the google group that should be used within Google Groups for RBAC feature as authenticator security group.

### Fleet management

Fleet management is achieved by the configuration of the fleet_configmanagement_templates, fleet_configmanagement_clusters and fleet_features variables exposed by the module in _module. In details fleet_features lets you activate the fleet features, fleet_configmanagement_templates lets you define one o more fleet configmanagement configuration template to be activated onto one or more GKE clusters. Configured features and settings can be applied to clusters by leveraging fleet_configmanagement_clusters where a single template can be applied to one or more clusters.

In the example below, we're defining a configuring the configmanagement feature with the name default, only config_sync is configured, other features have been left inactive.

The entire fleet (fleet_features) has been configured to have multiclusterservicediscovery and multiclusteringress active; pay attention that multiclusteringress is not a bool, it's a string since MCI requires a configuration cluster.

The variable fleet_configmanagement_clusters is used to activate the configmanagement feature on the given set of clusters.

```
fleet_configmanagement_templates = {
  default = {
    binauthz = false
    config_sync = {
      git = {
        gcp_service_account_email = null
        https_proxy               = null
        policy_dir                = "configsync"
        secret_type               = "none"
        source_format             = "hierarchy"
        sync_branch               = "main"
        sync_repo                 = "https://github.com/.../..."
        sync_rev                  = null
        sync_wait_secs            = null
      }
      prevent_drift = true
      source_format = "hierarchy"
    }
    hierarchy_controller = null
    policy_controller    = null
    version              = "1.10.2"
  }
}

fleet_configmanagement_clusters = {
  default = ["gke-1", "gke-2"]
}

fleet_features = {
  appdevexperience             = false
  configmanagement             = false
  identityservice              = false
  multiclusteringress          = "gke-1"
  multiclusterservicediscovery = true
  servicemesh                  = false
}
```


## How to run this stage

This stage is meant to be executed after "foundational stages" (i.e., stages [`00-bootstrap`](../../00-bootstrap), [`01-resman`](../../01-resman), 02-networking (either [VPN](../../02-networking-vpn) or [NVA](../../02-networking-nva)) and [`02-security`](../../02-security)) have been run.

It's of course possible to run this stage in isolation, by making sure the architectural prerequisites are satisfied (e.g., networking), and that the Service Account running the stage is granted the roles/permissions below:

...

### Providers configuration

TODO

### Variable configuration

TODO

<!-- TFDOC OPTS files:1 show_extra:1 -->
<!-- BEGIN TFDOC -->

## Files

| name | description | modules | resources |
|---|---|---|---|
| [main.tf](./main.tf) | GKE multitenant for development environment. | <code>_module</code> |  |
| [outputs.tf](./outputs.tf) | Output variables. |  | <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [automation](variables.tf#L21) | Automation resources created by the bootstrap stage. | <code title="object&#40;&#123;&#10;  outputs_bucket &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>00-bootstrap</code> |
| [billing_account](variables.tf#L35) | Billing account id and organization id ('nnnnnnnn' or null). | <code title="object&#40;&#123;&#10;  id              &#61; string&#10;  organization_id &#61; number&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>00-bootstrap</code> |
| [clusters](variables.tf#L74) |  | <code title="map&#40;object&#40;&#123;&#10;  cluster_autoscaling &#61; object&#40;&#123;&#10;    cpu_min    &#61; number&#10;    cpu_max    &#61; number&#10;    memory_min &#61; number&#10;    memory_max &#61; number&#10;  &#125;&#41;&#10;  description &#61; string&#10;  dns_domain  &#61; string&#10;  labels      &#61; map&#40;string&#41;&#10;  location    &#61; string&#10;  net &#61; object&#40;&#123;&#10;    master_range &#61; string&#10;    pods         &#61; string&#10;    services     &#61; string&#10;    subnet       &#61; string&#10;  &#125;&#41;&#10;  overrides &#61; object&#40;&#123;&#10;    cloudrun_config         &#61; bool&#10;    database_encryption_key &#61; string&#10;    master_authorized_ranges        &#61; map&#40;string&#41;&#10;    max_pods_per_node               &#61; number&#10;    pod_security_policy             &#61; bool&#10;    release_channel                 &#61; string&#10;    vertical_pod_autoscaling        &#61; bool&#10;    gcp_filestore_csi_driver_config &#61; bool&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |  |
| [folder_ids](variables.tf#L176) | Folders to be used for the networking resources in folders/nnnnnnnnnnn format. If null, folder will be created. | <code title="object&#40;&#123;&#10;  gke-dev &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>01-resman</code> |
| [host_project_ids](variables.tf#L198) | Host project for the shared VPC. | <code title="object&#40;&#123;&#10;  dev-spoke-0 &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>02-networking</code> |
| [nodepools](variables.tf#L230) |  | <code title="map&#40;map&#40;object&#40;&#123;&#10;  node_count         &#61; number&#10;  node_type          &#61; string&#10;  initial_node_count &#61; number&#10;  overrides &#61; object&#40;&#123;&#10;    image_type        &#61; string&#10;    max_pods_per_node &#61; number&#10;    node_locations    &#61; list&#40;string&#41;&#10;    node_tags         &#61; list&#40;string&#41;&#10;    node_taints       &#61; list&#40;string&#41;&#10;  &#125;&#41;&#10;  spot &#61; bool&#10;&#125;&#41;&#41;&#41;">map&#40;map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;&#41;</code> | ✓ |  |  |
| [prefix](variables.tf#L253) | Prefix used for resources that need unique names. | <code>string</code> | ✓ |  |  |
| [vpc_self_links](variables.tf#L265) | Self link for the shared VPC. | <code title="object&#40;&#123;&#10;  dev-spoke-0 &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>02-networking</code> |
| [authenticator_security_group](variables.tf#L29) | Optional group used for Groups for GKE. | <code>string</code> |  | <code>null</code> |  |
| [cluster_defaults](variables.tf#L44) | Default values for optional cluster configurations. | <code title="object&#40;&#123;&#10;  cloudrun_config                 &#61; bool&#10;  database_encryption_key         &#61; string&#10;  master_authorized_ranges        &#61; map&#40;string&#41;&#10;  max_pods_per_node               &#61; number&#10;  pod_security_policy             &#61; bool&#10;  release_channel                 &#61; string&#10;  vertical_pod_autoscaling        &#61; bool&#10;  gcp_filestore_csi_driver_config &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  cloudrun_config         &#61; false&#10;  database_encryption_key &#61; null&#10;  master_authorized_ranges &#61; &#123;&#10;    rfc1918_1 &#61; &#34;10.0.0.0&#47;8&#34;&#10;    rfc1918_2 &#61; &#34;172.16.0.0&#47;12&#34;&#10;    rfc1918_3 &#61; &#34;192.168.0.0&#47;16&#34;&#10;  &#125;&#10;  max_pods_per_node               &#61; 110&#10;  pod_security_policy             &#61; false&#10;  release_channel                 &#61; &#34;STABLE&#34;&#10;  vertical_pod_autoscaling        &#61; false&#10;  gcp_filestore_csi_driver_config &#61; false&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [dns_domain](variables.tf#L107) | Domain name used for clusters, prefixed by each cluster name. Leave null to disable Cloud DNS for GKE. | <code>string</code> |  | <code>null</code> |  |
| [fleet_configmanagement_clusters](variables.tf#L113) | Config management features enabled on specific sets of member clusters, in config name => [cluster name] format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [fleet_configmanagement_templates](variables.tf#L121) | Sets of config management configurations that can be applied to member clusters, in config name => {options} format. | <code title="map&#40;object&#40;&#123;&#10;  binauthz &#61; bool&#10;  config_sync &#61; object&#40;&#123;&#10;    git &#61; object&#40;&#123;&#10;      gcp_service_account_email &#61; string&#10;      https_proxy               &#61; string&#10;      policy_dir                &#61; string&#10;      secret_type               &#61; string&#10;      sync_branch               &#61; string&#10;      sync_repo                 &#61; string&#10;      sync_rev                  &#61; string&#10;      sync_wait_secs            &#61; number&#10;    &#125;&#41;&#10;    prevent_drift &#61; string&#10;    source_format &#61; string&#10;  &#125;&#41;&#10;  hierarchy_controller &#61; object&#40;&#123;&#10;    enable_hierarchical_resource_quota &#61; bool&#10;    enable_pod_tree_labels             &#61; bool&#10;  &#125;&#41;&#10;  policy_controller &#61; object&#40;&#123;&#10;    audit_interval_seconds     &#61; number&#10;    exemptable_namespaces      &#61; list&#40;string&#41;&#10;    log_denies_enabled         &#61; bool&#10;    referential_rules_enabled  &#61; bool&#10;    template_library_installed &#61; bool&#10;  &#125;&#41;&#10;  version &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [fleet_features](variables.tf#L156) | Enable and configue fleet features. Set to null to disable GKE Hub if fleet workload identity is not used. | <code title="object&#40;&#123;&#10;  appdevexperience             &#61; bool&#10;  configmanagement             &#61; bool&#10;  identityservice              &#61; bool&#10;  multiclusteringress          &#61; string&#10;  multiclusterservicediscovery &#61; bool&#10;  servicemesh                  &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |  |
| [fleet_workload_identity](variables.tf#L169) | Use Fleet Workload Identity for clusters. Enables GKE Hub if set to true. | <code>bool</code> |  | <code>true</code> |  |
| [group_iam](variables.tf#L184) | Project-level authoritative IAM bindings for groups in {GROUP_EMAIL => [ROLES]} format. Use group emails as keys, list of roles as values. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [iam](variables.tf#L191) | Project-level authoritative IAM bindings for users and service accounts in  {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [labels](variables.tf#L206) | Project-level labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [nodepool_defaults](variables.tf#L212) |  | <code title="object&#40;&#123;&#10;  image_type        &#61; string&#10;  max_pods_per_node &#61; number&#10;  node_locations    &#61; list&#40;string&#41;&#10;  node_tags         &#61; list&#40;string&#41;&#10;  node_taints       &#61; list&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  image_type        &#61; &#34;COS_CONTAINERD&#34;&#10;  max_pods_per_node &#61; 110&#10;  node_locations    &#61; null&#10;  node_tags         &#61; null&#10;  node_taints       &#61; &#91;&#93;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [outputs_location](variables.tf#L247) | Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable. | <code>string</code> |  | <code>null</code> |  |
| [project_services](variables.tf#L258) | Additional project services to enable. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [cluster_ids](outputs.tf#L63) | Cluster ids. |  |  |
| [clusters](outputs.tf#L57) | Cluster resources. | ✓ |  |
| [project_id](outputs.tf#L68) | GKE project id. |  |  |

<!-- END TFDOC -->
