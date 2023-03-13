# Google Cloud Dataproc

This module Manages a Google Cloud [Dataproc](https://cloud.google.com/dataproc) cluster resource, including IAM.

## TODO

- [ ] Add support for Cloud Dataproc [autoscaling policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataproc_autoscaling_policy_iam).

## Examples

### Simple

```hcl
module "processing-dp-cluster-2" {
  source     = "./fabric/modules/dataproc"
  project_id = "my-project"
  name       = "my-cluster"
  region     = "europe-west1"
}
# tftest modules=1 resources=1
```

### Cluster configuration

To set cluster configuration use the 'dataproc_config.cluster_config' variable.

```hcl
module "processing-dp-cluster" {
  source     = "./fabric/modules/dataproc"
  project_id = "my-project"
  name       = "my-cluster"
  region     = "europe-west1"
  prefix     = "prefix"
  dataproc_config = {
    cluster_config = {
      gce_cluster_config = {
        subnetwork             = "https://www.googleapis.com/compute/v1/projects/PROJECT/regions/europe-west1/subnetworks/SUBNET"
        zone                   = "europe-west1-b"
        service_account        = ""
        service_account_scopes = ["cloud-platform"]
        internal_ip_only       = true
      }
    }
  }
}
# tftest modules=1 resources=1
```

### Cluster with CMEK encryption

To set cluster configuration use the Customer Managed Encryption key, set `dataproc_config.encryption_config.` variable. The Compute Engine service agent and the Cloud Storage service agent need to have `CryptoKey Encrypter/Decrypter` role on they configured KMS key ([Documentation](https://cloud.google.com/dataproc/docs/concepts/configuring-clusters/customer-managed-encryption)).

```hcl
module "processing-dp-cluster" {
  source     = "./fabric/modules/dataproc"
  project_id = "my-project"
  name       = "my-cluster"
  region     = "europe-west1"
  prefix     = "prefix"
  dataproc_config = {
    cluster_config = {
      gce_cluster_config = {
        subnetwork             = "https://www.googleapis.com/compute/v1/projects/PROJECT/regions/europe-west1/subnetworks/SUBNET"
        zone                   = "europe-west1-b"
        service_account        = ""
        service_account_scopes = ["cloud-platform"]
        internal_ip_only       = true
      }
    }
    encryption_config = {
      kms_key_name = "projects/project-id/locations/region/keyRings/key-ring-name/cryptoKeys/key-name"
    }
  }
}
# tftest modules=1 resources=1
```

## IAM Examples

IAM is managed via several variables that implement different levels of control:

- `group_iam` and `iam` configure authoritative bindings that manage individual roles exclusively, mapping to the `google_dataproc_cluster_iam_binding` resource
- `iam_additive` configure additive bindings that only manage individual role/member pairs, mapping to the `google_dataproc_cluster_iam_member` resource

### Authoritative IAM

The iam variable is based on role keys and is typically used for service accounts, or where member values can be dynamic and would create potential problems in the underlying for_each cycle.

```hcl
module "processing-dp-cluster" {
  source     = "./fabric/modules/dataproc"
  project_id = "my-project"
  name       = "my-cluster"
  region     = "europe-west1"
  prefix     = "prefix"
  iam = {
    "roles/dataproc.viewer" = [
      "serviceAccount:service-account@PROJECT_ID.iam.gserviceaccount.com"
    ]
  }
}
# tftest modules=1 resources=2
```

The group_iam variable uses group email addresses as keys and is a convenient way to assign roles to humans following Google's best practices. The end result is readable code that also serves as documentation.

```hcl
module "processing-dp-cluster" {
  source     = "./fabric/modules/dataproc"
  project_id = "my-project"
  name       = "my-cluster"
  region     = "europe-west1"
  prefix     = "prefix"
  group_iam = {
    "gcp-data-engineers@example.net" = [
      "roles/dataproc.viewer"
    ]
  }
}
# tftest modules=1 resources=2
```

### Additive IAM

Additive IAM is typically used where bindings for specific roles are controlled by different modules or in different Terraform stages. One example is when the cluster is created by one team but a different team manages access.

```hcl
module "processing-dp-cluster" {
  source     = "./fabric/modules/dataproc"
  project_id = "my-project"
  name       = "my-cluster"
  region     = "europe-west1"
  prefix     = "prefix"
  iam_additive = {
    "roles/dataproc.viewer" = [
      "serviceAccount:service-account@PROJECT_ID.iam.gserviceaccount.com"
    ]
  }
}
# tftest modules=1 resources=2
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L211) | Cluster name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L226) | Project ID. | <code>string</code> | ✓ |  |
| [region](variables.tf#L231) | Dataproc region. | <code>string</code> | ✓ |  |
| [dataproc_config](variables.tf#L17) | Dataproc cluster config. | <code title="object&#40;&#123;&#10;  graceful_decommission_timeout &#61; optional&#40;string&#41;&#10;  cluster_config &#61; optional&#40;object&#40;&#123;&#10;    staging_bucket &#61; optional&#40;string&#41;&#10;    temp_bucket    &#61; optional&#40;string&#41;&#10;    gce_cluster_config &#61; optional&#40;object&#40;&#123;&#10;      zone                   &#61; optional&#40;string&#41;&#10;      network                &#61; optional&#40;string&#41;&#10;      subnetwork             &#61; optional&#40;string&#41;&#10;      service_account        &#61; optional&#40;string&#41;&#10;      service_account_scopes &#61; optional&#40;list&#40;string&#41;&#41;&#10;      tags                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;      internal_ip_only       &#61; optional&#40;bool&#41;&#10;      metadata               &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;      reservation_affinity &#61; optional&#40;object&#40;&#123;&#10;        consume_reservation_type &#61; string&#10;        key                      &#61; string&#10;        values                   &#61; string&#10;      &#125;&#41;&#41;&#10;      node_group_affinity &#61; optional&#40;object&#40;&#123;&#10;        node_group_uri &#61; string&#10;      &#125;&#41;&#41;&#10;&#10;&#10;      shielded_instance_config &#61; optional&#40;object&#40;&#123;&#10;        enable_secure_boot          &#61; bool&#10;        enable_vtpm                 &#61; bool&#10;        enable_integrity_monitoring &#61; bool&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    master_config &#61; optional&#40;object&#40;&#123;&#10;      num_instances    &#61; number&#10;      machine_type     &#61; string&#10;      min_cpu_platform &#61; string&#10;      disk_config &#61; optional&#40;object&#40;&#123;&#10;        boot_disk_type    &#61; string&#10;        boot_disk_size_gb &#61; number&#10;        num_local_ssds    &#61; number&#10;      &#125;&#41;&#41;&#10;      accelerators &#61; optional&#40;object&#40;&#123;&#10;        accelerator_type  &#61; string&#10;        accelerator_count &#61; number&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    worker_config &#61; optional&#40;object&#40;&#123;&#10;      num_instances    &#61; number&#10;      machine_type     &#61; string&#10;      min_cpu_platform &#61; string&#10;      disk_config &#61; optional&#40;object&#40;&#123;&#10;        boot_disk_type    &#61; string&#10;        boot_disk_size_gb &#61; number&#10;        num_local_ssds    &#61; number&#10;      &#125;&#41;&#41;&#10;      image_uri &#61; string&#10;      accelerators &#61; optional&#40;object&#40;&#123;&#10;        accelerator_type  &#61; string&#10;        accelerator_count &#61; number&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    preemptible_worker_config &#61; optional&#40;object&#40;&#123;&#10;      num_instances  &#61; number&#10;      preemptibility &#61; string&#10;      disk_config &#61; optional&#40;object&#40;&#123;&#10;        boot_disk_type    &#61; string&#10;        boot_disk_size_gb &#61; number&#10;        num_local_ssds    &#61; number&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    software_config &#61; optional&#40;object&#40;&#123;&#10;      image_version       &#61; optional&#40;string&#41;&#10;      override_properties &#61; map&#40;string&#41;&#10;      optional_components &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    security_config &#61; optional&#40;object&#40;&#123;&#10;      kerberos_config &#61; object&#40;&#123;&#10;        cross_realm_trust_admin_server        &#61; optional&#40;string&#41;&#10;        cross_realm_trust_kdc                 &#61; optional&#40;string&#41;&#10;        cross_realm_trust_realm               &#61; optional&#40;string&#41;&#10;        cross_realm_trust_shared_password_uri &#61; optional&#40;string&#41;&#10;        enable_kerberos                       &#61; optional&#40;string&#41;&#10;        kdc_db_key_uri                        &#61; optional&#40;string&#41;&#10;        key_password_uri                      &#61; optional&#40;string&#41;&#10;        keystore_uri                          &#61; optional&#40;string&#41;&#10;        keystore_password_uri                 &#61; optional&#40;string&#41;&#10;        kms_key_uri                           &#61; string&#10;        realm                                 &#61; optional&#40;string&#41;&#10;        root_principal_password_uri           &#61; string&#10;        tgt_lifetime_hours                    &#61; optional&#40;string&#41;&#10;        truststore_password_uri               &#61; optional&#40;string&#41;&#10;        truststore_uri                        &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#41;&#10;    autoscaling_config &#61; optional&#40;object&#40;&#123;&#10;      policy_uri &#61; string&#10;    &#125;&#41;&#41;&#10;    initialization_action &#61; optional&#40;object&#40;&#123;&#10;      script      &#61; string&#10;      timeout_sec &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    encryption_config &#61; optional&#40;object&#40;&#123;&#10;      kms_key_name &#61; string&#10;    &#125;&#41;&#41;&#10;    lifecycle_config &#61; optional&#40;object&#40;&#123;&#10;      idle_delete_ttl  &#61; optional&#40;string&#41;&#10;      auto_delete_time &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    endpoint_config &#61; optional&#40;object&#40;&#123;&#10;      enable_http_port_access &#61; string&#10;    &#125;&#41;&#41;&#10;    dataproc_metric_config &#61; optional&#40;object&#40;&#123;&#10;      metrics &#61; list&#40;object&#40;&#123;&#10;        metric_source    &#61; string&#10;        metric_overrides &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    metastore_config &#61; optional&#40;object&#40;&#123;&#10;      dataproc_metastore_service &#61; string&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#10;&#10;  virtual_cluster_config &#61; optional&#40;object&#40;&#123;&#10;    staging_bucket &#61; optional&#40;string&#41;&#10;    auxiliary_services_config &#61; optional&#40;object&#40;&#123;&#10;      metastore_config &#61; optional&#40;object&#40;&#123;&#10;        dataproc_metastore_service &#61; string&#10;      &#125;&#41;&#41;&#10;      spark_history_server_config &#61; optional&#40;object&#40;&#123;&#10;        dataproc_cluster &#61; string&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    kubernetes_cluster_config &#61; object&#40;&#123;&#10;      kubernetes_namespace &#61; optional&#40;string&#41;&#10;      kubernetes_software_config &#61; object&#40;&#123;&#10;        component_version &#61; list&#40;map&#40;string&#41;&#41;&#10;        properties        &#61; optional&#40;list&#40;map&#40;string&#41;&#41;&#41;&#10;      &#125;&#41;&#10;&#10;&#10;      gke_cluster_config &#61; object&#40;&#123;&#10;        gke_cluster_target &#61; optional&#40;string&#41;&#10;        node_pool_target &#61; optional&#40;object&#40;&#123;&#10;          node_pool &#61; string&#10;          roles     &#61; list&#40;string&#41;&#10;          node_pool_config &#61; optional&#40;object&#40;&#123;&#10;            autoscaling &#61; optional&#40;object&#40;&#123;&#10;              min_node_count &#61; optional&#40;number&#41;&#10;              max_node_count &#61; optional&#40;number&#41;&#10;            &#125;&#41;&#41;&#10;&#10;&#10;            config &#61; object&#40;&#123;&#10;              machine_type     &#61; optional&#40;string&#41;&#10;              preemptible      &#61; optional&#40;bool&#41;&#10;              local_ssd_count  &#61; optional&#40;number&#41;&#10;              min_cpu_platform &#61; optional&#40;string&#41;&#10;              spot             &#61; optional&#40;bool&#41;&#10;            &#125;&#41;&#10;&#10;&#10;            locations &#61; optional&#40;list&#40;string&#41;&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [group_iam](variables.tf#L184) | Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L191) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_additive](variables.tf#L198) | IAM additive bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L205) | The resource labels for instance to use to annotate any related underlying resources, such as Compute Engine VMs. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L216) | Optional prefix used to generate project id and name. | <code>string</code> |  | <code>null</code> |
| [service_account](variables.tf#L236) | Service account to set on the Dataproc cluster. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [bucket_names](outputs.tf#L19) | List of bucket names which have been assigned to the cluster. |  |
| [http_ports](outputs.tf#L24) | The map of port descriptions to URLs. |  |
| [instance_names](outputs.tf#L29) | List of instance names which have been assigned to the cluster. |  |
| [name](outputs.tf#L38) | The name of the cluster. |  |

<!-- END TFDOC -->
