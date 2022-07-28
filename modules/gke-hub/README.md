# GKE hub module

This module allows simplified creation and management of a GKE Hub object and its features for a given set of clusters. The given list of clusters will be registered inside the Hub and all the configured features will be activated.

To use this module you must ensure the following APIs are enabled in the target project:
```
"gkehub.googleapis.com"
"gkeconnect.googleapis.com"
"anthosconfigmanagement.googleapis.com"
"multiclusteringress.googleapis.com"
"multiclusterservicediscovery.googleapis.com"
"mesh.googleapis.com"
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
    "mesh.googleapis.com"
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
  clusters = {
    cluster-1 = module.cluster-1.id
  }
  features = {
<<<<<<< HEAD
    appdevexperience       = false
=======
    cloudrun               = false
>>>>>>> 579efb76 (Fixes)
    configmanagement       = true
    identity-service       = false
    ingress                = null
    multi-cluster-services = false
    servicemesh            = false
  }
  configmanagement_templates = {
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
          sync_repo                 = "https://github.com/danielmarzini/configsync-platform-example"
          sync_rev                  = null
          sync_wait_secs            = null
        }
        prevent_drift = false
        source_format = "hierarchy"
      }
      hierarchy_controller = {
        enable_hierarchical_resource_quota = true
        enable_pod_tree_labels             = true
      }
      policy_controller = {
        audit_interval_seconds     = 120
        exemptable_namespaces      = []
        log_denies_enabled         = true
        referential_rules_enabled  = true
        template_library_installed = true
      }
      version = "v1"
    }
  }
  configmanagement_clusters = {
<<<<<<< HEAD
    "default" = [ "cluster-1" ]
=======
    "common" = [ "cluster-1" ]
>>>>>>> 37906d9d (Fixes)
  }
}

# tftest modules=4 resources=15
```

## Multi-cluster mesh on GKE

```hcl
module "project" {
  source          = "./modules/project"
  billing_account = local.billing_account_id
  name            = "gkehub-test"
  parent          = "folders/12345"
  services = [
    "anthos.googleapis.com",
    "container.googleapis.com",
    "gkehub.googleapis.com",
    "gkeconnect.googleapis.com",
    "mesh.googleapis.com",
    "meshconfig.googleapis.com",
    "meshca.googleapis.com"
  ]
}

module "vpc" {
  source     = "./modules/net-vpc"
  project_id = module.project.project_id
  name       = "svpc"
  mtu        = 1500
  subnets = [
    {
      ip_cidr_range = config.subnet_cidr_block
      name          = "subnet-cluster-1"
      region        = "europe-west1"
      secondary_ip_range = {
        pods     = "10.1.0.0/16"
        services = "10.2.0.0/24"
    },
    {
      ip_cidr_range = config.subnet_cidr_block
      name          = "subnet-cluster-2"
      region        = "europe-west4"
      secondary_ip_range = {
        pods     = "10.3.0.0/16"
        services = "10.4.0.0/24"
    },
    {
      ip_cidr_range      = "10.0.0.0/28"
      name               = "subnet-mgmt"
      region             = "europe-west1"
      secondary_ip_range = null
    }
  ])
}

module "firewall" {
  source     = "./modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.vpc.name
  custom_rules = { 
    allow-mesh = {
      description          = "Allow "
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      ranges               = ["10.1.0.0/16", "10.3.0.0/16"]
      targets              = ["cluster-1-node", "cluster-2-node""]
      use_service_accounts = false
      rules = [{ protocol = "tcp", ports = null },
        { protocol = "udp", ports = null },
        { protocol = "icmp", ports = null },
        { protocol = "esp", ports = null },
        { protocol = "ah", ports = null },
      { protocol = "sctp", ports = null }]
      extra_attributes = {
        priority = 900
      }
    }, 
    "allow-cluster-1-istio" => {
      description          = "Allow "
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      ranges               = [ "192.168.1.0/28" ]
      targets              = ["cluster-1-node"]
      use_service_accounts = false
      rules                = [{ protocol = "tcp", ports = [8080, 15014, 15017] }]
      extra_attributes = {
        priority = 1000
      }
    },
    "allow-cluster-2-istio" => {
      description          = "Allow "
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      ranges               = [ "192.168.2.0/28" ]
      targets              = ["cluster-2-node"]
      use_service_accounts = false
      rules                = [{ protocol = "tcp", ports = [8080, 15014, 15017] }]
      extra_attributes = {
        priority = 1000
      }
    }
  }
}

module "cluster_1" {
  source                   = "./modules/gke-cluster"
  project_id               = module.project.project_id
  name                     = "cluster-1"
  location                 = "europe-wes1"
  network                  = module.vpc.self_link
  subnetwork               = module.vpc.subnet_self_links["europe-wes1/subnet-cluster-1"]
  secondary_range_pods     = "pods"
  secondary_range_services = "services"
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = ["192.168.1.0/28"]
    master_global_access    = true
  }
  master_authorized_ranges = {
    mgmt = ["10.0.0.0/28"]
    "pods-cluster-1" = [ "10.3.0.0/16"]
  }
  enable_autopilot  = false
  release_channel   = "REGULAR"
  workload_identity = true
  labels = {
    mesh_id = "proj-${module.project.number}"
  }
}

module "cluster_1_nodepool" {
  source                      = "./module/gke-nodepool"
  project_id                  = module.project.project_id
  cluster_name                = module.cluster_1.name
  location                    = "europe-west1"
  name                        = "nodepool"
  node_service_account_create = true
  initial_node_count          = 1
  node_machine_type           = "e2-standard-4"
  node_tags                   = ["cluster-1-node"]
}

module "cluster_2" {
  source                   = "./modules/gke-cluster"
  project_id               = module.project.project_id
  name                     = "cluster-1"
  location                 = "europe-wes1"
  network                  = module.vpc.self_link
  subnetwork               = module.vpc.subnet_self_links["europe-wes1/subnet-cluster-1"]
  secondary_range_pods     = "pods"
  secondary_range_services = "services"
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = ["192.168.2.0/28"]
    master_global_access    = true
  }
  master_authorized_ranges = {
    mgmt = ["10.0.0.0/28"]
    "pods-cluster-1" = [ "10.1.0.0/16"]
  }
  enable_autopilot  = false
  release_channel   = "REGULAR"
  workload_identity = true
  labels = {
    mesh_id = "proj-${module.project.number}"
  }
}

module "cluster_2_nodepool" {
  source                      = "./module/gke-nodepool"
  project_id                  = module.project.project_id
  cluster_name                = module.cluster_2.name
  location                    = "europe-west4"
  name                        = "nodepool"
  node_service_account_create = true
  initial_node_count          = 1
  node_machine_type           = "e2-standard-4"
  node_tags                   = ["cluster-2-node"]
}


module "hub" {
  source     = "./modules/gke-hub"
  project_id = module.project.project_id
  clusters = { 
    cluster-1 = module.cluster_1.id
    cluster-2 = module.cluster_2.id
  }
  features = {
    cloudrun               = false
    configmanagement       = false
    identity-service       = false
    ingress                = null
    multi-cluster-services = false
    servicemesh            = true
  }
  workload_identity_clusters = keys(module.clusters)
}

# tftest modules=4 resources=15
```




<!-- BEGIN TFDOC -->

## Variables


## Outputs


<!-- END TFDOC -->
