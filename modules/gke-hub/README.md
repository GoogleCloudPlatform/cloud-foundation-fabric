# GKE hub module

This module allows simplified creation and management of a GKE Hub object and its features for a given set of clusters. The given list of clusters will be registered inside the Hub and all the configured features will be activated.

To use this module you must ensure the following APIs are enabled in the target project:
```
"gkehub.googleapis.com"
"gkeconnect.googleapis.com"
"anthosconfigmanagement.googleapis.com"
"multiclusteringress.googleapis.com"
"multiclusterservicediscovery.googleapis.com"
```

## Full GKE Hub example

```hcl
module "project" {
  source          = "./modules/project"
  billing_account = var.billing_account_id
  name            = "gkehub-test"
  parent          = "folders/12345"
  services = [
    "container.googleapis.com",
    "gkehub.googleapis.com",
    "gkeconnect.googleapis.com",
    "anthosconfigmanagement.googleapis.com",
    "multiclusteringress.googleapis.com",
    "multiclusterservicediscovery.googleapis.com",
  ]
}

module "vpc" {
  source     = "./modules/net-vpc"
  project_id = module.project.project_id
  name       = "network"
  subnets = [{
    ip_cidr_range = "10.0.0.0/24"
    name          = "cluster-1"
    region        = "europe-west1"
    secondary_ip_range = {
      pods     = "10.1.0.0/16"
      services = "10.2.0.0/24"
    }
  }]
}

module "cluster-1" {
  source                   = "./modules/gke-cluster"
  project_id               = module.project.project_id
  name                     = "cluster-1"
  location                 = "europe-west1-b"
  network                  = module.vpc.self_link
  subnetwork               = module.vpc.subnet_self_links["europe-west1/cluster-1"]
  secondary_range_pods     = "pods"
  secondary_range_services = "services"
  enable_dataplane_v2      = true
  master_authorized_ranges = { rfc1918_10_8 = "10.0.0.0/8" }
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "192.168.0.0/28"
    master_global_access    = false
  }
}

module "hub" {
  source     = "./modules/gke-hub"
  project_id = module.project.project_id
  member_clusters = {
    cluster1 = module.cluster-1.id
  }
  member_features = {
    configmanagement = {
      binauthz = true
      config_sync = {
        gcp_service_account_email = null
        https_proxy               = null
        policy_dir                = "configsync"
        secret_type               = "none"
        source_format             = "hierarchy"
        sync_branch               = "main"
        sync_repo                 = "https://github.com/danielmarzini/configsync-platform-example"
        sync_rev                  = null
      }
      hierarchy_controller = null
      policy_controller    = null
      version              = "1.10.2"
    }
  }
}

# tftest modules=4 resources=13
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L75) | GKE hub project ID. | <code>string</code> | ✓ |  |
| [features](variables.tf#L17) | GKE hub features to enable. | <code title="object&#40;&#123;&#10;  configmanagement    &#61; bool&#10;  mc_ingress          &#61; bool&#10;  mc_servicediscovery &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  configmanagement    &#61; true&#10;  mc_ingress          &#61; false&#10;  mc_servicediscovery &#61; false&#10;&#125;">&#123;&#8230;&#125;</code> |
| [member_clusters](variables.tf#L32) | List for member cluster self links. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [member_features](variables.tf#L39) | Member features for each cluster | <code title="object&#40;&#123;&#10;  configmanagement &#61; object&#40;&#123;&#10;    binauthz &#61; bool&#10;    config_sync &#61; object&#40;&#123;&#10;      gcp_service_account_email &#61; string&#10;      https_proxy               &#61; string&#10;      policy_dir                &#61; string&#10;      secret_type               &#61; string&#10;      source_format             &#61; string&#10;      sync_branch               &#61; string&#10;      sync_repo                 &#61; string&#10;      sync_rev                  &#61; string&#10;    &#125;&#41;&#10;    hierarchy_controller &#61; object&#40;&#123;&#10;      enable_hierarchical_resource_quota &#61; bool&#10;      enable_pod_tree_labels             &#61; bool&#10;    &#125;&#41;&#10;    policy_controller &#61; object&#40;&#123;&#10;      exemptable_namespaces      &#61; list&#40;string&#41;&#10;      log_denies_enabled         &#61; bool&#10;      referential_rules_enabled  &#61; bool&#10;      template_library_installed &#61; bool&#10;    &#125;&#41;&#10;    version &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  configmanagement &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cluster_ids](outputs.tf#L17) |  |  |

<!-- END TFDOC -->
