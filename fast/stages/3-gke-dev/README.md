# GKE Multitenant

This stage allows creation and management of a fleet of GKE multitenant clusters for a single environment, optionally leveraging GKE Hub to configure additional features.

The following diagram illustrates the high-level design of created resources, which can be adapted to specific requirements via variables:

<p align="center">
  <img src="diagram.png" alt="GKE multitenant">
</p>

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
- [How to run this stage](#how-to-run-this-stage)
  - [Resource management configuration](#resource-management-configuration)
  - [Provider and Terraform variables](#provider-and-terraform-variables)
  - [Impersonating the automation service account](#impersonating-the-automation-service-account)
  - [Variable configuration](#variable-configuration)
  - [Running the stage](#running-the-stage)
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

This stage is meant to be executed after the FAST "foundational" stages: bootstrap, resource management, security and networking stages.

It's of course possible to run this stage in isolation, refer to the *[Running in isolation](#running-in-isolation)* section below for details.

Before running this stage, you need to make sure you have the correct credentials and permissions, and localize variables by assigning values that match your configuration.

### Resource management configuration

Some configuration changes are needed in resource management before this stage can be run.

First, define a parent folder for each stage environment folder in the `data/top-level-folder` folder [in the resource management stage](../1-resman/data/top-level-folders/). As an example, this YAML definition creates a `GKE` folder under the organization:

```yaml
# yaml-language-server: $schema=../../schemas/top-level-folder.schema.json

name: GKE

# IAM bindings and organization policies can also be defined here
```

Then, edit the definition of the networking stage 2 in the `data/stage2` folder [in the resource management stage](../1-resman/data/stage-2/) to include the IAM configuration for GKE. The following are example snippets for GKE dev, make sure they match the `short_name` and `environment` configured above.

In `folder_config.iam_bindings_additive` add:

```yaml
# folder_config:
  # iam_bindings_additive:
    gke_dns_admin:
      role: roles/dns.admin
      member: gke-dev-ro
      condition:
        title: GKE dev DNS admin.
        expression: |
          resource.matchTag('${organization.id}/${tag_names.environment}', 'development')
    gke_dns_reader:
      role: roles/dns.reader
      member: gke-dev-ro
      condition:
        title: GKE dev DNS reader.
        expression: |
          resource.matchTag('${organization.id}/${tag_names.environment}', 'development')
```

### Provider and Terraform variables

As all other FAST stages, the [mechanism used to pass variable values and pre-built provider files from one stage to the next](../0-bootstrap/README.md#output-files-and-cross-stage-variables) is also leveraged here.

The commands to link or copy the provider and terraform variable files can be easily derived from the `fast-links.sh` script in the FAST root folder, passing it a single argument with the local output files folder (if configured) or the GCS output bucket in the automation project (derived from stage 0 outputs). The following examples demonstrate both cases, and the resulting commands that then need to be copy/pasted and run.

```bash
../fast-links.sh ~/fast-config

# File linking commands for GKE (dev) stage

# provider file
ln -s ~/fast-config/providers/3-gke-dev-providers.tf ./

# input files from other stages
ln -s ~/fast-config/tfvars/0-globals.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/0-bootstrap.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/1-resman.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/2-networking.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
ln -s ~/fast-config/3-gke-dev.auto.tfvars ./
```

```bash
../fast-links.sh gs://xxx-prod-iac-core-outputs-0

# File linking commands for GKE (dev) stage

# provider file
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/providers/3-gke-dev-providers.tf ./

# input files from other stages
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/1-resman.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/2-networking.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/3-gke-dev.auto.tfvars ./
```

### Impersonating the automation service account

The preconfigured provider file uses impersonation to run with this stage's automation service account's credentials. The `gcp-devops` and `organization-admins` groups have the necessary IAM bindings in place to do that, so make sure the current user is a member of one of those groups.

### Variable configuration

Variables in this stage -- like most other FAST stages -- are broadly divided into three separate sets:

- variables which refer to global values for the whole organization (org id, billing account id, prefix, etc.), which are pre-populated via the `0-globals.auto.tfvars.json` file linked or copied above
- variables which refer to resources managed by previous stage, which are prepopulated here via the `*.auto.tfvars.json` files linked or copied above
- and finally variables that optionally control this stage's behaviour and customizations, and can to be set in a custom `terraform.tfvars` file

The latter set is explained in the [Customization](#customizations) sections below, and the full list can be found in the [Variables](#variables) table at the bottom of this document.

### Running the stage

Once provider and variable values are in place and the correct user is configured, the stage can be run:

```bash
terraform init
terraform apply
```

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

If clusters share similar configurations, those can be centralized via `locals` blocks in this stage's `main.tf` file, and merged in with clusters via a simple `for_each` loop.

### Fleet management

Fleet management is entirely optional, and uses two separate variables:

- `fleet_config`: specifies the [GKE fleet](https://cloud.google.com/anthos/fleet-management/docs/fleet-concepts#fleet-enabled-components) features to activate
- `fleet_configmanagement_templates`: defines configuration templates for specific sets of features ([Config Management](https://cloud.google.com/anthos-config-management/docs/how-to/install-anthos-config-management) currently)

Clusters can then be configured for fleet registration and one of the config management templates attached via the cluster-level `fleet_config` attribute.

<!-- TFDOC OPTS files:1 show_extra:1 exclude:3-gke-dev-providers.tf -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules |
|---|---|---|
| [gke-clusters.tf](./gke-clusters.tf) | GKE clusters. | <code>gke-cluster-standard</code> · <code>gke-nodepool</code> |
| [gke-hub.tf](./gke-hub.tf) | GKE hub configuration. | <code>gke-hub</code> |
| [main.tf](./main.tf) | Project and usage dataset. | <code>bigquery-dataset</code> · <code>iam-service-account</code> · <code>project</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [variables-fast.tf](./variables-fast.tf) | None |  |
| [variables-fleet.tf](./variables-fleet.tf) | GKE fleet configurations. |  |
| [variables.tf](./variables.tf) | Module variables. |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [billing_account](variables-fast.tf#L17) | Billing account id. If billing account is not part of the same org set `is_org_level` to false. | <code title="object&#40;&#123;&#10;  id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [environments](variables-fast.tf#L25) | Long environment names. | <code title="object&#40;&#123;&#10;  dev &#61; object&#40;&#123;&#10;    name &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>1-resman</code> |
| [prefix](variables-fast.tf#L51) | Prefix used for resources that need unique names. Use a maximum of 9 chars for organizations, and 11 chars for tenants. | <code>string</code> | ✓ |  | <code>0-bootstrap</code> |
| [clusters](variables.tf#L17) | Clusters configuration. Refer to the gke-cluster module for type details. | <code title="map&#40;object&#40;&#123;&#10;  access_config &#61; optional&#40;object&#40;&#123;&#10;    dns_access &#61; optional&#40;bool, true&#41;&#10;    ip_access &#61; optional&#40;object&#40;&#123;&#10;      authorized_ranges               &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;      disable_public_endpoint         &#61; optional&#40;bool, true&#41;&#10;      gcp_public_cidrs_access_enabled &#61; optional&#40;bool, false&#41;&#10;      private_endpoint_config &#61; optional&#40;object&#40;&#123;&#10;        endpoint_subnetwork &#61; optional&#40;string&#41;&#10;        global_access       &#61; optional&#40;bool, true&#41;&#10;      &#125;&#41;, &#123;&#125;&#41;&#10;    &#125;&#41;&#41;&#10;    private_nodes &#61; optional&#40;bool, true&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  cluster_autoscaling &#61; optional&#40;any&#41;&#10;  description         &#61; optional&#40;string&#41;&#10;  enable_addons &#61; optional&#40;any, &#123;&#10;    horizontal_pod_autoscaling &#61; true, http_load_balancing &#61; true&#10;  &#125;&#41;&#10;  enable_features &#61; optional&#40;any, &#123;&#10;    shielded_nodes    &#61; true&#10;    workload_identity &#61; true&#10;  &#125;&#41;&#10;  fleet_config &#61; optional&#40;object&#40;&#123;&#10;    register                  &#61; optional&#40;bool, true&#41;&#10;    configmanagement_template &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  issue_client_certificate &#61; optional&#40;bool, false&#41;&#10;  labels                   &#61; optional&#40;map&#40;string&#41;&#41;&#10;  location                 &#61; string&#10;  logging_config &#61; optional&#40;object&#40;&#123;&#10;    enable_system_logs             &#61; optional&#40;bool, true&#41;&#10;    enable_workloads_logs          &#61; optional&#40;bool, true&#41;&#10;    enable_api_server_logs         &#61; optional&#40;bool, false&#41;&#10;    enable_scheduler_logs          &#61; optional&#40;bool, false&#41;&#10;    enable_controller_manager_logs &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  maintenance_config &#61; optional&#40;any, &#123;&#10;    daily_window_start_time &#61; &#34;03:00&#34;&#10;    recurring_window        &#61; null&#10;    maintenance_exclusion   &#61; &#91;&#93;&#10;  &#125;&#41;&#10;  max_pods_per_node  &#61; optional&#40;number, 110&#41;&#10;  min_master_version &#61; optional&#40;string&#41;&#10;  monitoring_config &#61; optional&#40;object&#40;&#123;&#10;    enable_system_metrics &#61; optional&#40;bool, true&#41;&#10;    enable_api_server_metrics         &#61; optional&#40;bool, false&#41;&#10;    enable_controller_manager_metrics &#61; optional&#40;bool, false&#41;&#10;    enable_scheduler_metrics          &#61; optional&#40;bool, false&#41;&#10;    enable_daemonset_metrics   &#61; optional&#40;bool, false&#41;&#10;    enable_deployment_metrics  &#61; optional&#40;bool, false&#41;&#10;    enable_hpa_metrics         &#61; optional&#40;bool, false&#41;&#10;    enable_pod_metrics         &#61; optional&#40;bool, false&#41;&#10;    enable_statefulset_metrics &#61; optional&#40;bool, false&#41;&#10;    enable_storage_metrics     &#61; optional&#40;bool, false&#41;&#10;    enable_managed_prometheus &#61; optional&#40;bool, true&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  node_locations  &#61; optional&#40;list&#40;string&#41;&#41;&#10;  release_channel &#61; optional&#40;string&#41;&#10;  vpc_config &#61; object&#40;&#123;&#10;    subnetwork &#61; string&#10;    network    &#61; optional&#40;string&#41;&#10;    secondary_range_blocks &#61; optional&#40;object&#40;&#123;&#10;      pods     &#61; string&#10;      services &#61; string&#10;    &#125;&#41;&#41;&#10;    secondary_range_names &#61; optional&#40;object&#40;&#123;&#10;      pods     &#61; string&#10;      services &#61; string&#10;    &#125;&#41;, &#123; pods &#61; &#34;pods&#34;, services &#61; &#34;services&#34; &#125;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [deletion_protection](variables.tf#L98) | Prevent Terraform from destroying data resources. | <code>bool</code> |  | <code>false</code> |  |
| [fleet_config](variables-fleet.tf#L19) | Fleet configuration. | <code title="object&#40;&#123;&#10;  enable_features &#61; optional&#40;object&#40;&#123;&#10;    appdevexperience             &#61; optional&#40;bool, false&#41;&#10;    configmanagement             &#61; optional&#40;bool, false&#41;&#10;    identityservice              &#61; optional&#40;bool, false&#41;&#10;    multiclusteringress          &#61; optional&#40;string, null&#41;&#10;    multiclusterservicediscovery &#61; optional&#40;bool, false&#41;&#10;    servicemesh                  &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  use_workload_identity &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |  |
| [fleet_configmanagement_templates](variables-fleet.tf#L35) | Sets of fleet configurations that can be applied to member clusters, in config name => {options} format. | <code title="map&#40;object&#40;&#123;&#10;  binauthz &#61; optional&#40;bool&#41;&#10;  version  &#61; optional&#40;string&#41;&#10;  config_sync &#61; object&#40;&#123;&#10;    git &#61; optional&#40;object&#40;&#123;&#10;      sync_repo                 &#61; string&#10;      policy_dir                &#61; string&#10;      gcp_service_account_email &#61; optional&#40;string&#41;&#10;      https_proxy               &#61; optional&#40;string&#41;&#10;      secret_type               &#61; optional&#40;string, &#34;none&#34;&#41;&#10;      sync_branch               &#61; optional&#40;string&#41;&#10;      sync_rev                  &#61; optional&#40;string&#41;&#10;      sync_wait_secs            &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    prevent_drift &#61; optional&#40;bool&#41;&#10;    source_format &#61; optional&#40;string, &#34;hierarchy&#34;&#41;&#10;  &#125;&#41;&#10;  hierarchy_controller &#61; optional&#40;object&#40;&#123;&#10;    enable_hierarchical_resource_quota &#61; optional&#40;bool&#41;&#10;    enable_pod_tree_labels             &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  policy_controller &#61; object&#40;&#123;&#10;    audit_interval_seconds     &#61; optional&#40;number&#41;&#10;    exemptable_namespaces      &#61; optional&#40;list&#40;string&#41;&#41;&#10;    log_denies_enabled         &#61; optional&#40;bool&#41;&#10;    referential_rules_enabled  &#61; optional&#40;bool&#41;&#10;    template_library_installed &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [folder_ids](variables-fast.tf#L35) | Folder name => id mappings. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>1-resman</code> |
| [host_project_ids](variables-fast.tf#L43) | Shared VPC host project name => id mappings. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
| [iam](variables.tf#L105) | Project-level authoritative IAM bindings for users and service accounts in  {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [iam_by_principals](variables.tf#L112) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [nodepools](variables.tf#L119) | Nodepools configuration. Refer to the gke-nodepool module for type details. | <code title="map&#40;map&#40;object&#40;&#123;&#10;  gke_version       &#61; optional&#40;string&#41;&#10;  k8s_labels        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  max_pods_per_node &#61; optional&#40;number&#41;&#10;  name              &#61; optional&#40;string&#41;&#10;  node_config &#61; optional&#40;any, &#123;&#10;    disk_type &#61; &#34;pd-balanced&#34;&#10;    shielded_instance_config &#61; &#123;&#10;      enable_integrity_monitoring &#61; true&#10;      enable_secure_boot          &#61; true&#10;    &#125;&#10;  &#125;&#41;&#10;  node_count &#61; optional&#40;map&#40;number&#41;, &#123;&#10;    initial &#61; 1&#10;  &#125;&#41;&#10;  node_locations        &#61; optional&#40;list&#40;string&#41;&#41;&#10;  nodepool_config       &#61; optional&#40;any&#41;&#10;  pod_range             &#61; optional&#40;any&#41;&#10;  reservation_affinity  &#61; optional&#40;any&#41;&#10;  service_account       &#61; optional&#40;any&#41;&#10;  sole_tenant_nodegroup &#61; optional&#40;string&#41;&#10;  tags                  &#61; optional&#40;list&#40;string&#41;&#41;&#10;  taints &#61; optional&#40;map&#40;object&#40;&#123;&#10;    value  &#61; string&#10;    effect &#61; string&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;&#41;&#41;">map&#40;map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [stage_config](variables.tf#L152) | FAST stage configuration used to find resource ids. Must match name defined for the stage in resource management. | <code title="object&#40;&#123;&#10;  environment &#61; string&#10;  name        &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  environment &#61; &#34;dev&#34;&#10;  name        &#61; &#34;gke-dev&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [subnet_self_links](variables-fast.tf#L61) | Subnet VPC name => { name => self link }  mappings. | <code>map&#40;map&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
| [vpc_config](variables.tf#L164) | VPC-level configuration for project and clusters. | <code title="object&#40;&#123;&#10;  host_project_id &#61; string&#10;  vpc_self_link   &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  host_project_id &#61; &#34;dev-spoke-0&#34;&#10;  vpc_self_link   &#61; &#34;dev-spoke-0&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [vpc_self_links](variables-fast.tf#L69) | Shared VPC name => self link mappings. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [cluster_ids](outputs.tf#L15) | Cluster ids. |  |  |
| [clusters](outputs.tf#L22) | Cluster resources. | ✓ |  |
| [project_id](outputs.tf#L28) | GKE project id. |  |  |
<!-- END TFDOC -->
