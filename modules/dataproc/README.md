# Google Cloud Dataproc

This module Manages a Google Cloud [Dataproc](https://cloud.google.com/dataproc) cluster resource, including IAM.

<!-- BEGIN TOC -->
- [TODO](#todo)
- [Examples](#examples)
  - [Simple](#simple)
  - [Cluster configuration on GCE](#cluster-configuration-on-gce)
  - [Cluster configuration on GCE with CMEK encryption](#cluster-configuration-on-gce-with-cmek-encryption)
  - [Cluster configuration on GKE](#cluster-configuration-on-gke)
- [IAM](#iam)
  - [Authoritative IAM](#authoritative-iam)
  - [Additive IAM](#additive-iam)
- [Variables](#variables)
- [Outputs](#outputs)
- [Fixtures](#fixtures)
<!-- END TOC -->

## TODO

- [ ] Add support for Cloud Dataproc [autoscaling policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataproc_autoscaling_policy_iam).

## Examples

### Simple

```hcl
module "dataproc-cluster" {
  source     = "./fabric/modules/dataproc"
  project_id = var.project_id
  name       = "my-cluster"
  region     = var.region
}
# tftest modules=1 resources=1
```

### Cluster configuration on GCE

To set cluster configuration use the 'dataproc_config.cluster_config' variable. If you don't want to use dedicated service account, remember to grant `roles/dataproc.worker` to Compute Default Service Account.

```hcl
module "dataproc-service-account" {
  source     = "./fabric/modules/iam-service-account"
  project_id = var.project_id
  name       = "dataproc-worker"
  iam_project_roles = {
    (var.project_id) = ["roles/dataproc.worker"]
  }
}

module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = var.project_id
  network    = var.vpc.name
  ingress_rules = {
    allow-ingress-dataproc = {
      description = "Allow all traffic between Dataproc nodes."
      targets     = ["dataproc"]
      sources     = ["dataproc"]
    }
  }
}

module "processing-dp-cluster" {
  source     = "./fabric/modules/dataproc"
  project_id = var.project_id
  name       = "my-cluster"
  region     = var.region
  dataproc_config = {
    cluster_config = {
      gce_cluster_config = {
        internal_ip_only       = true
        service_account        = module.dataproc-service-account.email
        service_account_scopes = ["cloud-platform"]
        subnetwork             = var.subnet.self_link
        tags                   = ["dataproc"]
        zone                   = "${var.region}-b"
      }
    }
  }
  depends_on = [
    module.dataproc-service-account, # ensure all grants are done before creating the cluster
  ]
}
# tftest modules=3 resources=7 e2e
```

### Cluster configuration on GCE with CMEK encryption

To set cluster configuration use the Customer Managed Encryption key, set `dataproc_config.encryption_config.` variable. The Compute Engine service agent and the Cloud Storage service agent need to have `CryptoKey Encrypter/Decrypter` role on they configured KMS key ([Documentation](https://cloud.google.com/dataproc/docs/concepts/configuring-clusters/customer-managed-encryption)).

```hcl
module "project" {
  source          = "./fabric/modules/project"
  name            = "dataproc"
  billing_account = var.billing_account_id
  prefix          = var.prefix
  parent          = var.folder_id
  services = [
    "cloudkms.googleapis.com",
    "dataproc.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

module "kms" {
  source     = "./fabric/modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = var.region
    name     = "keyring"
  }
  keys = {
    "key-regional" = {
    }
  }
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      module.project.service_agents.dataproc.iam_email
    ]
  }
}

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = module.project.project_id
  name       = "my-network"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "production"
      region        = var.region
    },
  ]
  psa_configs = [{
    ranges = { myrange = "10.0.1.0/24" }
  }]
}

module "dataproc-service-account" {
  source     = "./fabric/modules/iam-service-account"
  project_id = module.project.project_id
  name       = "dataproc-worker"
  iam_project_roles = {
    (module.project.project_id) = ["roles/dataproc.worker", "roles/cloudkms.cryptoKeyEncrypterDecrypter"]
  }
}

module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.vpc.name
  ingress_rules = {
    allow-ingress-dataproc = {
      description = "Allow all traffic between Dataproc nodes."
      targets     = ["dataproc"]
      sources     = ["dataproc"]
    }
  }
}

module "processing-dp-cluster" {
  source     = "./fabric/modules/dataproc"
  project_id = module.project.project_id
  name       = "my-cluster"
  region     = var.region
  dataproc_config = {
    cluster_config = {
      gce_cluster_config = {
        internal_ip_only       = true
        service_account        = module.dataproc-service-account.email
        service_account_scopes = ["cloud-platform"]
        subnetwork             = module.vpc.subnet_self_links["${var.region}/production"]
        tags                   = ["dataproc"]
        zone                   = "${var.region}-b"
      }
    }
    encryption_config = {
      kms_key_name = module.kms.keys.key-regional.id
    }
  }
}
# tftest modules=6 resources=28 e2e
```

### Cluster configuration on GKE

To set cluster configuration GKE use the 'dataproc_config.virtual_cluster_config' variable. This example shows usage of [dedicated Service Account](https://cloud.google.com/dataproc/docs/guides/dpgke/dataproc-gke-iam#custom_iam_configuration).

```hcl
locals {
  dataproc_namespace = "foobar"
}

module "dataproc-service-account" {
  source     = "./fabric/modules/iam-service-account"
  project_id = var.project_id
  name       = "dataproc-worker"
  iam = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${var.project_id}.svc.id.goog[${local.dataproc_namespace}/agent]",
      "serviceAccount:${var.project_id}.svc.id.goog[${local.dataproc_namespace}/spark-driver]",
      "serviceAccount:${var.project_id}.svc.id.goog[${local.dataproc_namespace}/spark-executor]"
    ]
  }
  iam_project_roles = {
    (var.project_id) = ["roles/dataproc.worker"]
  }
  depends_on = [
    module.gke-cluster-standard, # granting workloadIdentityUser requires cluster/pool to be created first
  ]
}

module "processing-dp-cluster" {
  source     = "./fabric/modules/dataproc"
  project_id = var.project_id
  name       = "my-dataproc-cluster"
  region     = var.region
  dataproc_config = {
    virtual_cluster_config = {
      kubernetes_cluster_config = {
        kubernetes_namespace = local.dataproc_namespace
        kubernetes_software_config = {
          component_version = {
            "SPARK" : "3.1-dataproc-14"
          }
          properties = {
            "dataproc:dataproc.gke.agent.google-service-account"          = module.dataproc-service-account.email
            "dataproc:dataproc.gke.spark.driver.google-service-account"   = module.dataproc-service-account.email
            "dataproc:dataproc.gke.spark.executor.google-service-account" = module.dataproc-service-account.email
          }
        }
        gke_cluster_config = {
          gke_cluster_target = module.gke-cluster-standard.id
          node_pool_target = {
            node_pool = "node-pool-name"
            roles     = ["DEFAULT"]
          }
        }
      }
    }
  }
}
# tftest modules=4 resources=6 fixtures=fixtures/gke-cluster-standard.tf e2e
```

## IAM

IAM is managed via several variables that implement different features and levels of control:

- `iam` and `iam_by_principals` configure authoritative bindings that manage individual roles exclusively, and are internally merged
- `iam_bindings` configure authoritative bindings with optional support for conditions, and are not internally merged with the previous two variables
- `iam_bindings_additive` configure additive bindings via individual role/member pairs with optional support  conditions

The authoritative and additive approaches can be used together, provided different roles are managed by each. Some care must also be taken with the `iam_by_principals` variable to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

Refer to the [project module](../project/README.md#iam) for examples of the IAM interface.

### Authoritative IAM

```hcl
module "processing-dp-cluster" {
  source     = "./fabric/modules/dataproc"
  project_id = var.project_id
  name       = "my-cluster"
  region     = var.region
  iam_by_principals = {
    "group:gcp-data-engineers@example.net" = [
      "roles/dataproc.viewer"
    ]
  }
  iam = {
    "roles/dataproc.viewer" = [
      "serviceAccount:service-account@PROJECT_ID.iam.gserviceaccount.com"
    ]
  }
}
# tftest modules=1 resources=2
```

### Additive IAM

```hcl
module "processing-dp-cluster" {
  source     = "./fabric/modules/dataproc"
  project_id = var.project_id
  name       = "my-cluster"
  region     = var.region
  iam_bindings_additive = {
    am1-viewer = {
      member = "user:am1@example.com"
      role   = "roles/dataproc.viewer"
    }
  }
}
# tftest modules=1 resources=2
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L191) | Cluster name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L196) | Project ID. | <code>string</code> | ✓ |  |
| [region](variables.tf#L201) | Dataproc region. | <code>string</code> | ✓ |  |
| [dataproc_config](variables.tf#L17) | Dataproc cluster config. | <code title="object&#40;&#123;&#10;  graceful_decommission_timeout &#61; optional&#40;string&#41;&#10;  cluster_config &#61; optional&#40;object&#40;&#123;&#10;    staging_bucket &#61; optional&#40;string&#41;&#10;    temp_bucket    &#61; optional&#40;string&#41;&#10;    gce_cluster_config &#61; optional&#40;object&#40;&#123;&#10;      zone                   &#61; optional&#40;string&#41;&#10;      network                &#61; optional&#40;string&#41;&#10;      subnetwork             &#61; optional&#40;string&#41;&#10;      service_account        &#61; optional&#40;string&#41;&#10;      service_account_scopes &#61; optional&#40;list&#40;string&#41;&#41;&#10;      tags                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;      internal_ip_only       &#61; optional&#40;bool&#41;&#10;      metadata               &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;      reservation_affinity &#61; optional&#40;object&#40;&#123;&#10;        consume_reservation_type &#61; string&#10;        key                      &#61; string&#10;        values                   &#61; string&#10;      &#125;&#41;&#41;&#10;      node_group_affinity &#61; optional&#40;object&#40;&#123;&#10;        node_group_uri &#61; string&#10;      &#125;&#41;&#41;&#10;&#10;&#10;      shielded_instance_config &#61; optional&#40;object&#40;&#123;&#10;        enable_secure_boot          &#61; bool&#10;        enable_vtpm                 &#61; bool&#10;        enable_integrity_monitoring &#61; bool&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    master_config &#61; optional&#40;object&#40;&#123;&#10;      num_instances    &#61; number&#10;      machine_type     &#61; optional&#40;string&#41;&#10;      min_cpu_platform &#61; optional&#40;string&#41;&#10;      image_uri        &#61; optional&#40;string&#41;&#10;      disk_config &#61; optional&#40;object&#40;&#123;&#10;        boot_disk_type    &#61; string&#10;        boot_disk_size_gb &#61; number&#10;        num_local_ssds    &#61; number&#10;      &#125;&#41;&#41;&#10;      accelerators &#61; optional&#40;object&#40;&#123;&#10;        accelerator_type  &#61; string&#10;        accelerator_count &#61; number&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    worker_config &#61; optional&#40;object&#40;&#123;&#10;      num_instances    &#61; number&#10;      machine_type     &#61; string&#10;      min_cpu_platform &#61; string&#10;      disk_config &#61; optional&#40;object&#40;&#123;&#10;        boot_disk_type    &#61; string&#10;        boot_disk_size_gb &#61; number&#10;        num_local_ssds    &#61; number&#10;      &#125;&#41;&#41;&#10;      image_uri &#61; string&#10;      accelerators &#61; optional&#40;object&#40;&#123;&#10;        accelerator_type  &#61; string&#10;        accelerator_count &#61; number&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    preemptible_worker_config &#61; optional&#40;object&#40;&#123;&#10;      num_instances  &#61; number&#10;      preemptibility &#61; string&#10;      disk_config &#61; optional&#40;object&#40;&#123;&#10;        boot_disk_type    &#61; string&#10;        boot_disk_size_gb &#61; number&#10;        num_local_ssds    &#61; number&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    software_config &#61; optional&#40;object&#40;&#123;&#10;      image_version       &#61; optional&#40;string&#41;&#10;      override_properties &#61; map&#40;string&#41;&#10;      optional_components &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    security_config &#61; optional&#40;object&#40;&#123;&#10;      kerberos_config &#61; object&#40;&#123;&#10;        cross_realm_trust_admin_server        &#61; optional&#40;string&#41;&#10;        cross_realm_trust_kdc                 &#61; optional&#40;string&#41;&#10;        cross_realm_trust_realm               &#61; optional&#40;string&#41;&#10;        cross_realm_trust_shared_password_uri &#61; optional&#40;string&#41;&#10;        enable_kerberos                       &#61; optional&#40;string&#41;&#10;        kdc_db_key_uri                        &#61; optional&#40;string&#41;&#10;        key_password_uri                      &#61; optional&#40;string&#41;&#10;        keystore_uri                          &#61; optional&#40;string&#41;&#10;        keystore_password_uri                 &#61; optional&#40;string&#41;&#10;        kms_key_uri                           &#61; string&#10;        realm                                 &#61; optional&#40;string&#41;&#10;        root_principal_password_uri           &#61; string&#10;        tgt_lifetime_hours                    &#61; optional&#40;string&#41;&#10;        truststore_password_uri               &#61; optional&#40;string&#41;&#10;        truststore_uri                        &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#41;&#10;    autoscaling_config &#61; optional&#40;object&#40;&#123;&#10;      policy_uri &#61; string&#10;    &#125;&#41;&#41;&#10;    initialization_action &#61; optional&#40;object&#40;&#123;&#10;      script      &#61; string&#10;      timeout_sec &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    encryption_config &#61; optional&#40;object&#40;&#123;&#10;      kms_key_name &#61; string&#10;    &#125;&#41;&#41;&#10;    lifecycle_config &#61; optional&#40;object&#40;&#123;&#10;      idle_delete_ttl  &#61; optional&#40;string&#41;&#10;      auto_delete_time &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    endpoint_config &#61; optional&#40;object&#40;&#123;&#10;      enable_http_port_access &#61; string&#10;    &#125;&#41;&#41;&#10;    dataproc_metric_config &#61; optional&#40;object&#40;&#123;&#10;      metrics &#61; list&#40;object&#40;&#123;&#10;        metric_source    &#61; string&#10;        metric_overrides &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    metastore_config &#61; optional&#40;object&#40;&#123;&#10;      dataproc_metastore_service &#61; string&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#10;&#10;  virtual_cluster_config &#61; optional&#40;object&#40;&#123;&#10;    staging_bucket &#61; optional&#40;string&#41;&#10;    auxiliary_services_config &#61; optional&#40;object&#40;&#123;&#10;      metastore_config &#61; optional&#40;object&#40;&#123;&#10;        dataproc_metastore_service &#61; string&#10;      &#125;&#41;&#41;&#10;      spark_history_server_config &#61; optional&#40;object&#40;&#123;&#10;        dataproc_cluster &#61; string&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    kubernetes_cluster_config &#61; object&#40;&#123;&#10;      kubernetes_namespace &#61; optional&#40;string&#41;&#10;      kubernetes_software_config &#61; object&#40;&#123;&#10;        component_version &#61; map&#40;string&#41;&#10;        properties        &#61; optional&#40;map&#40;string&#41;&#41;&#10;      &#125;&#41;&#10;&#10;&#10;      gke_cluster_config &#61; object&#40;&#123;&#10;        gke_cluster_target &#61; optional&#40;string&#41;&#10;        node_pool_target &#61; optional&#40;object&#40;&#123;&#10;          node_pool &#61; string&#10;          roles     &#61; list&#40;string&#41;&#10;          node_pool_config &#61; optional&#40;object&#40;&#123;&#10;            autoscaling &#61; optional&#40;object&#40;&#123;&#10;              min_node_count &#61; optional&#40;number&#41;&#10;              max_node_count &#61; optional&#40;number&#41;&#10;            &#125;&#41;&#41;&#10;&#10;&#10;            config &#61; object&#40;&#123;&#10;              machine_type     &#61; optional&#40;string&#41;&#10;              preemptible      &#61; optional&#40;bool&#41;&#10;              local_ssd_count  &#61; optional&#40;number&#41;&#10;              min_cpu_platform &#61; optional&#40;string&#41;&#10;              spot             &#61; optional&#40;bool&#41;&#10;            &#125;&#41;&#10;&#10;&#10;            locations &#61; optional&#40;list&#40;string&#41;&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables-iam.tf#L24) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L31) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L46) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L17) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L185) | The resource labels for instance to use to annotate any related underlying resources, such as Compute Engine VMs. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L30) | Fully qualified cluster id. |  |
| [name](outputs.tf#L45) | The name of the cluster. |  |

## Fixtures

- [gke-cluster-standard.tf](../../tests/fixtures/gke-cluster-standard.tf)
<!-- END TFDOC -->
