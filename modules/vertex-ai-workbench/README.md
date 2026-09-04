# Google Cloud Vertex AI Workbench Instance Module

This module manages Google Cloud Vertex AI Workbench (Jupyter Notebook) instances, supporting machine types, GPU hardware accelerators, private VPC networking, Shielded VM options, service account management, and IAM permissions.

<!-- BEGIN TOC -->
- [Basic Workbench Instance](#basic-workbench-instance)
- [Workbench Instance with GPU, Private VPC, and Custom VM Image](#workbench-instance-with-gpu-private-vpc-and-custom-vm-image)
- [Enterprise Workbench with Service Account and IAM](#enterprise-workbench-with-service-account-and-iam)
- [Custom Container Image and Context Interpolation](#custom-container-image-and-context-interpolation)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Basic Workbench Instance

```hcl
module "workbench" {
  source       = "./fabric/modules/vertex-ai-workbench"
  project_id   = var.project_id
  prefix       = "test"
  name         = "my-workbench"
  location     = "us-central1-a"
  machine_type = "e2-standard-4"
}
# tftest modules=1 resources=1
```

## Workbench Instance with GPU, Private VPC, and Custom VM Image

```hcl
module "workbench_gpu" {
  source            = "./fabric/modules/vertex-ai-workbench"
  project_id        = var.project_id
  prefix            = "test"
  name              = "gpu-workbench"
  location          = "europe-west1-b"
  machine_type      = "n1-standard-8"
  disable_public_ip = true
  accelerator_config = {
    type       = "NVIDIA_TESLA_T4"
    core_count = 1
  }
  vm_image = {
    family  = "common-cu121-debian-11-py310"
    project = "deeplearning-platform-release"
  }
  network_interfaces = [
    {
      network  = var.vpc.self_link
      subnet   = var.subnet.self_link
      nic_type = "GVNIC"
    }
  ]
  boot_disk = {
    disk_size_gb    = 150
    disk_type       = "PD_SSD"
    disk_encryption = "GMEK"
  }
  data_disks = {
    disk_size_gb = 200
    disk_type    = "PD_STANDARD"
  }
  shielded_instance_config = {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }
  tags = ["notebook", "gpu"]
}
# tftest modules=1 resources=1
```

## Enterprise Workbench with Service Account and IAM

```hcl
module "workbench_enterprise" {
  source                     = "./fabric/modules/vertex-ai-workbench"
  project_id                 = var.project_id
  name                       = "enterprise-wb"
  location                   = "us-central1-b"
  desired_state              = "ACTIVE"
  deletion_policy            = "DELETE"
  disable_proxy_access       = false
  enable_deletion_protection = false
  enable_ip_forwarding       = false
  min_cpu_platform           = "Intel Ice Lake"
  metadata_startup_script    = "echo 'Setup complete'"
  metadata = {
    environment = "production"
  }
  labels = {
    env = "prod"
  }
  instance_owners = ["user:lead-data-scientist@example.com"]
  confidential_instance_config = {
    confidential_instance_type = "SEV"
  }
  reservation_affinity = {
    consume_reservation_type = "RESERVATION_NONE"
  }
  service_account = {
    auto_create = true
  }
  iam = {
    "roles/notebooks.admin" = ["user:lead-data-scientist@example.com"]
  }
  iam_by_principals = {
    "group:ml-team@example.com" = ["roles/notebooks.viewer"]
  }
}
# tftest modules=1 resources=4
```

## Custom Container Image and Context Interpolation

```hcl
module "workbench_custom_image" {
  source     = "./fabric/modules/vertex-ai-workbench"
  project_id = var.project_id
  name       = "custom-wb"
  location   = "us-central1-a"
  container_image = {
    repository = "gcr.io/deeplearning-platform-release/base-cpu"
    tag        = "latest"
  }
  context = {
    locations = {
      "us-central1-a" = "us-central1-a"
    }
  }
}
# tftest modules=1 resources=1
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location](variables.tf#L155) | The zone in which the workbench instance should reside. | <code>string</code> | ✓ |  |
| [name](variables.tf#L184) | The name of the workbench instance. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L212) | The ID of the project in which the resource belongs. | <code>string</code> | ✓ |  |
| [accelerator_config](variables.tf#L15) | Hardware accelerator (GPU) configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [boot_disk](variables.tf#L24) | Boot disk configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [confidential_instance_config](variables.tf#L35) | Confidential instance configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [container_image](variables.tf#L43) | Container image for the workbench instance. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [context](variables.tf#L52) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_disks](variables.tf#L67) | Data disk configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [deletion_policy](variables.tf#L79) | Deletion policy for workbench instance (DELETE or ABANDON). | <code>string</code> |  | <code>null</code> |
| [desired_state](variables.tf#L92) | Desired state of Workbench Instance (ACTIVE or STOPPED). | <code>string</code> |  | <code>null</code> |
| [disable_proxy_access](variables.tf#L105) | If true, instance will not register with the proxy. | <code>bool</code> |  | <code>false</code> |
| [disable_public_ip](variables.tf#L111) | If true, no public IP will be assigned to the instance. | <code>bool</code> |  | <code>null</code> |
| [enable_deletion_protection](variables.tf#L117) | Whether deletion protection is enabled for this instance. | <code>bool</code> |  | <code>false</code> |
| [enable_ip_forwarding](variables.tf#L123) | Flag to enable IP forwarding. | <code>bool</code> |  | <code>null</code> |
| [iam](variables.tf#L129) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables.tf#L136) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [instance_owners](variables.tf#L143) | The list of owners of this instance after creation. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [labels](variables.tf#L149) | Labels that you can apply to your workbench instances. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [machine_type](variables.tf#L160) | The Compute Engine machine type of this instance. | <code>string</code> |  | <code>&#34;e2-standard-4&#34;</code> |
| [metadata](variables.tf#L166) | Custom metadata to apply to this instance. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [metadata_startup_script](variables.tf#L172) | Instance startup script. | <code>string</code> |  | <code>null</code> |
| [min_cpu_platform](variables.tf#L178) | Minimum CPU platform. | <code>string</code> |  | <code>null</code> |
| [network_interfaces](variables.tf#L189) | The list of network interfaces for the instance. | <code>list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |
| [prefix](variables.tf#L202) | Optional prefix used for resource names. | <code>string</code> |  | <code>null</code> |
| [reservation_affinity](variables.tf#L217) | Reservation affinity configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [service_account](variables.tf#L237) | Service account configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [shielded_instance_config](variables.tf#L247) | A set of Shielded Instance options. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [tags](variables.tf#L257) | Compute Engine tags to add to runtime. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [vm_image](variables.tf#L263) | Custom Compute Engine VM image to use. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [compute_instance_id](outputs.tf#L15) | The Compute Engine instance ID. |  |
| [create_time](outputs.tf#L23) | The time the instance was created. |  |
| [creator](outputs.tf#L28) | The email address of the user who created this instance. |  |
| [id](outputs.tf#L33) | An identifier for the resource. |  |
| [instance](outputs.tf#L42) | The Workbench instance resource. |  |
| [name](outputs.tf#L47) | The name of the workbench instance. |  |
| [proxy_uri](outputs.tf#L52) | The endpoint for accessing the Jupyter notebook. |  |
| [service_account](outputs.tf#L57) | The service account resource. |  |
| [service_account_email](outputs.tf#L62) | The service account email. |  |
| [service_account_iam_email](outputs.tf#L67) | The service account email formatted for IAM bindings. |  |
| [state](outputs.tf#L76) | The state of the workbench instance. |  |
<!-- END TFDOC -->
