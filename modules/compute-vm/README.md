# Google Compute Engine VM module

This module can operate in two distinct modes:

- instance creation, with optional unmanaged group
- instance template creation

In both modes, an optional service account can be created and assigned to either instances or template. If you need a managed instance group when using the module in template mode, refer to the [`compute-mig`](../compute-mig) module.

## Examples

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Instance using defaults](#instance-using-defaults)
  - [Service account management](#service-account-management)
    - [Compute default service account](#compute-default-service-account)
    - [Custom service account](#custom-service-account)
    - [Custom service account, auto created](#custom-service-account-auto-created)
    - [No service account](#no-service-account)
  - [Disk management](#disk-management)
    - [Disambiguating Disk "Names"](#disambiguating-disk-names)
    - [Disk sources](#disk-sources)
    - [Disk Ordering](#disk-ordering)
    - [Disk types and options](#disk-types-and-options)
    - [Boot disk as an independent resource](#boot-disk-as-an-independent-resource)
  - [Network interfaces](#network-interfaces)
    - [Internal and external IPs](#internal-and-external-ips)
    - [Using Alias IPs](#using-alias-ips)
    - [Using gVNIC](#using-gvnic)
    - [PSC interfaces](#psc-interfaces)
  - [Metadata](#metadata)
  - [IAM](#iam)
  - [Spot VM](#spot-vm)
  - [Confidential compute](#confidential-compute)
  - [Disk encryption with Cloud KMS](#disk-encryption-with-cloud-kms)
    - [External keys](#external-keys)
    - [KMS Autokey](#kms-autokey)
  - [Advanced machine features](#advanced-machine-features)
  - [Instance template](#instance-template)
    - [Global template](#global-template)
    - [Regional template](#regional-template)
  - [Instance group](#instance-group)
  - [Instance Schedule and Resource Policies](#instance-schedule-and-resource-policies)
  - [Snapshot Schedules](#snapshot-schedules)
  - [Resource Manager Tags](#resource-manager-tags)
  - [Sole Tenancy](#sole-tenancy)
- [Variables](#variables)
- [Outputs](#outputs)
- [Fixtures](#fixtures)
<!-- END TOC -->

### Instance using defaults

The simplest example leverages defaults for the boot disk image and size, and uses a service account created by the module. Multiple instances can be managed via the `instance_count` variable.

```hcl
module "simple-vm-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
}
# tftest modules=1 resources=1 inventory=defaults.yaml e2e
```

### Service account management

VM service accounts can be managed in four different ways:

- in its default configuration, the module uses the Compute default service account with a basic set of scopes (`devstorage.read_only`, `logging.write`, `monitoring.write`)
- a custom service account can be used by passing its email in the `service_account.email` variable
- a custom service account can be created by the module and used by setting the `service_account.auto_create` variable to `true`
- the instance can be created with no service account by setting the `service_account` variable to `null`

Scopes for custom service accounts are set by default to `cloud-platform` and `userinfo.email`, and can be further customized regardless of which service account is used by directly setting the `service_account.scopes` variable.

#### Compute default service account

```hcl
module "vm-managed-sa-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test1"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
}
# tftest inventory=sa-default.yaml e2e
```

#### Custom service account

```hcl
module "vm-managed-sa-example2" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test2"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  service_account = {
    email = module.iam-service-account.email
  }
}
# tftest inventory=sa-custom.yaml fixtures=fixtures/iam-service-account.tf e2e
```

#### Custom service account, auto created

```hcl
module "vm-managed-sa-example2" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test2"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  service_account = {
    auto_create = true
  }
}
# tftest inventory=sa-managed.yaml e2e
```

#### No service account

```hcl
module "vm-managed-sa-example2" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test2"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  service_account = null
}
# tftest inventory=sa-none.yaml e2e
```

### Disk management

#### Disambiguating Disk "Names"

Disks in GCP and Terraform have several identifiers which often cause confusion. This module explicitly disambiguates them as follows:

1. **Map Key (The Identifier):** In the `attached_disks` map, the key itself will act as the primary logical identifier for the disk within the module's Terraform state.
2. **Device Name (`device_name`):** This is the name exposed to the Guest OS (e.g., visible in `/dev/disk/by-id/google-<device_name>`). The module defaults the `device_name` to the **Map Key**. Users can override it explicitly if needed, but the map key provides a safe, predictable default.
3. **Resource Name (`name`):** This is the actual name of the `google_compute_disk` resource created in the GCP API. To ensure uniqueness across a project, the module defaults the resource name to `${var.name}-${each.key}` (the VM name hyphenated with the Map Key). An explicit `name` attribute can be provided to override this (e.g., when attaching an existing disk or requiring a specific naming convention).

#### Disk sources

Attached disks can be created and optionally initialized from a pre-existing source, or attached to VMs when pre-existing. The `source` attribute of the `attached_disks` variable allows several modes of operation:

- `source.image` can be used with zonal disks in instances and templates, set to the image name or self link
- `source.snapshot` can be used with instances only, set to the snapshot name or self link
- `source.attach` can be used for both instances and templates to attach an existing disk, set to the name (for zonal disks) or self link (for regional disks) of the existing disk to attach; no disk will be created
- `source = null` can be used where an empty disk is needed

> **Note:** When using `source.attach`, the value must be a statically known string (e.g., a self-link or ID of an existing disk). You cannot pass a dynamic reference (like `google_compute_disk.my_disk.id`) to a disk being created in the same Terraform apply cycle. This is an intentional design choice to maintain stable `for_each` keys. If you need to create a disk alongside the VM, let the module manage its creation by defining `initialize_params` instead.

#### Disk Ordering

When attaching multiple disks to a VM, Terraform processes them using a `dynamic` block based on the `attached_disks` map. By default, Terraform iterates over map keys in alphabetical order. This alphabetical order dictates the sequence in which disks are attached, which in turn influences the default `device_name` exposed to the guest OS (if not explicitly overridden).

If you add a new disk to the `attached_disks` map with a key that comes alphabetically *before* existing disks, it will shift the attachment order of all subsequent disks. This shift can cause Terraform to recreate or modify existing attachments, potentially requiring the VM to be restarted or remounted.

To explicitly control the attachment order and prevent unintended shifts when adding new disks, you can use the optional `position` attribute within each disk's configuration. The module uses the `position` value as the sorting key. If `position` is omitted, it falls back to using the map key itself.

By setting a `position` value that sorts alphabetically *after* the existing disks, you can safely append a newly added disk to the end of the attachment list, regardless of its actual map key.

This is an example of attaching a pre-existing regional PD to a new instance:

```hcl
module "vm-disks-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  attached_disks = {
    repd-1 = {
      initialize_params = {
        replica_zone = "${var.region}-c"
      }
      source = {
        attach = "regions/${var.region}/disks/repd-test-1"
      }
    }
  }
  service_account = {
    auto_create = true
  }
}
# tftest modules=1 resources=2
```

And the same example for an instance template (where not using the full self link of the disk triggers recreation of the template)

```hcl
module "vm-disks-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  attached_disks = {
    repd = {
      auto_delete = false
      initialize_params = {
        replica_zone = "${var.region}-c"
      }
      source = {
        attach = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.region}/disks/repd-test-1"
      }
    }
  }
  service_account = {
    auto_create = true
  }
  create_template = {}
}
# tftest inventory=disks-example-template.yaml
```

#### Disk types and options

The `attached_disks` variable exposes an `initialize_params` attribute that can be used to fine tune the configuration of each disk. The following example shows a VM with multiple disks

```hcl
module "vm-disk-options-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  attached_disks = {
    data1 = {
      initialize_params = {
        replica_zone = "${var.region}-c"
      }
      source = {
        image = "image-1"
      }
    }
    data0 = {
      position = "data2"
      mode     = "READ_ONLY"
      initialize_params = {
        size = 20
        type = "pd-ssd"
      }
      source = {
        snapshot = "snapshot-2"
      }
    }
  }
  service_account = {
    auto_create = true
  }
}
# tftest inventory=disk-options.yaml
```

For hyperdisks there are additional options available to configure performance.

```hcl
module "vm-disk-options-example" {
  source       = "./fabric/modules/compute-vm"
  project_id   = var.project_id
  zone         = "${var.region}-b"
  name         = "test"
  machine_type = "n4-standard-2"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  boot_disk = {
    initialize_params = {
      type = "hyperdisk-balanced"
      hyperdisk = {
        provisioned_iops       = 3000
        provisioned_throughput = 140
      }
    }
    source = {
      image = "projects/debian-cloud/global/images/family/debian-12"
    }
  }
  attached_disks = {
    data1 = {
      initialize_params = {
        type = "hyperdisk-balanced"
        hyperdisk = {
          provisioned_iops       = 3000
          provisioned_throughput = 140
        }
      }
    }
    data2 = {
      initialize_params = {
        type = "hyperdisk-balanced"
        hyperdisk = {
          provisioned_iops       = 5000
          provisioned_throughput = 500
        }
      }
      source = {
        image = "projects/debian-cloud/global/images/family/debian-12"
      }
    }
  }
  service_account = {
    auto_create = true
  }
  shielded_config = {}
}

# tftest inventory=disk-hyperdisk-cust-performance.yaml e2e
```

You can use storage pool for better management of storage capacity.

```hcl
# hyperdisk - with storage pool
resource "google_compute_storage_pool" "default" {
  project                      = var.project_id
  name                         = "storage-pool-basic"
  pool_provisioned_capacity_gb = "20480"
  pool_provisioned_iops        = "10000"
  pool_provisioned_throughput  = 1024
  storage_pool_type            = "hyperdisk-balanced"
  zone                         = "${var.region}-c"
  deletion_protection          = false
}

module "vm-disk-options-example" {
  source       = "./fabric/modules/compute-vm"
  project_id   = var.project_id
  zone         = "${var.region}-c"
  name         = "test"
  machine_type = "c4d-standard-2"
  network_interfaces = [
    {
      network    = var.vpc.self_link
      subnetwork = var.subnet.self_link
    }
  ]
  boot_disk = {
    use_independent_disk = {}
    initialize_params = {
      type = "hyperdisk-balanced"
      hyperdisk = {
        provisioned_iops       = 3000
        provisioned_throughput = 140
        storage_pool           = google_compute_storage_pool.default.id
      }
    }
    source = {
      image = "projects/debian-cloud/global/images/family/debian-12"
    }
  }
  attached_disks = {
    data1 = {
      initialize_params = {
        type = "hyperdisk-balanced"
        hyperdisk = {
          storage_pool = google_compute_storage_pool.default.id
        }
      }
    }
    data2 = {
      initialize_params = {
        type = "hyperdisk-balanced"
        hyperdisk = {
          provisioned_iops       = 5000
          provisioned_throughput = 500
        }
      }
      source = {
        image = "projects/debian-cloud/global/images/family/debian-12"
      }
    }
  }
  service_account = {
    auto_create = true
  }
  shielded_config = {}
}

# tftest inventory=disk-hyperdisk-pool.yaml e2e
```

You need to specify additional options if you are using ARM-based instances

For hyperdisks there are additional options available to configure performance.

```hcl
module "vm-arm" {
  source       = "./fabric/modules/compute-vm"
  project_id   = var.project_id
  zone         = "${var.region}-c"
  name         = "test"
  machine_type = "c4a-standard-1"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  boot_disk = {
    architecture = "ARM64"
    initialize_params = {
      type = "hyperdisk-balanced"
      hyperdisk = {
        provisioned_iops       = 3000
        provisioned_throughput = 140
      }
    }
    source = {
      image = "projects/debian-cloud/global/images/family/debian-12-arm64"
    }
  }
  attached_disks = {
    data1 = {
      initialize_params = {
        type = "hyperdisk-balanced"
        hyperdisk = {
          provisioned_iops       = 3000
          provisioned_throughput = 140
        }
      }
    }
    data2 = {
      initialize_params = {
        type = "hyperdisk-balanced"
        hyperdisk = {
          provisioned_iops       = 5000
          provisioned_throughput = 500
        }
      }
      source = {
        image = "projects/debian-cloud/global/images/family/debian-12-arm64"
      }
    }
  }
  service_account = {
    auto_create = true
  }
  shielded_config = {}
}

# tftest inventory=disk-hyperdisk-arm.yaml e2e
```

#### Boot disk as an independent resource

To create the boot disk as an independent resources instead of as part of the instance creation flow, set `boot_disk.use_independent_disk` to a non-null object (e.g. `{}`) and optionally configure `boot_disk.initialize_params`.

This will create the boot disk as its own resource and attach it to the instance, allowing to recreate the instance from Terraform while preserving the boot disk.

```hcl
module "simple-vm-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test"
  boot_disk = {
    use_independent_disk = {}
  }
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  service_account = {
    auto_create = true
  }
}
# tftest inventory=independent-boot-disk.yaml e2e
```

### Network interfaces

#### Internal and external IPs

By default VNs are create with an automatically assigned IP addresses, but you can change it through the `addresses` and `nat` attributes of the `network_interfaces` variable:

```hcl
module "vm-internal-ip" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "vm-internal-ip"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    addresses  = { internal = "10.0.0.2" }
  }]
}

module "vm-external-ip" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "vm-external-ip"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = true
    addresses  = { external = "8.8.8.8" }
  }]
}
# tftest inventory=ips.yaml
```

#### Using Alias IPs

This example shows how to add additional [Alias IPs](https://cloud.google.com/vpc/docs/alias-ip) to your VM. `alias_ips` is a map of subnetwork additional range name into IP address.

```hcl
module "vm-with-alias-ips" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    alias_ips = {
      services = "100.71.1.123/32"
    }
  }]
}
# tftest inventory=alias-ips.yaml e2e
```

#### Using gVNIC

This example shows how to enable [gVNIC](https://cloud.google.com/compute/docs/networking/using-gvnic) on your VM by customizing a `cos` image. Given that gVNIC needs to be enabled as an instance configuration and as a guest os configuration, you'll need to supply a bootable disk with `guest_os_features=GVNIC`. `SEV_CAPABLE`, `UEFI_COMPATIBLE` and `VIRTIO_SCSI_MULTIQUEUE` are enabled implicitly in the `cos`, `rhel`, `centos` and other images.

Note: most recent Google-provided images do enable `GVNIC` and no custom image is necessary.

```hcl
resource "google_compute_image" "cos-gvnic" {
  project      = var.project_id
  name         = "my-image"
  source_image = "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/images/cos-89-16108-534-18"
  guest_os_features {
    type = "GVNIC"
  }
  guest_os_features {
    type = "SEV_CAPABLE"
  }
  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }
  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }
}

module "vm-with-gvnic" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test"
  boot_disk = {
    initialize_params = {
      type = "pd-ssd"
    }
    source = {
      image = google_compute_image.cos-gvnic.self_link
    }
  }
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nic_type   = "GVNIC"
  }]
  service_account = {
    auto_create = true
  }
}
# tftest inventory=gvnic.yaml
```

#### PSC interfaces

[Private Service Connect interfaces](https://cloud.google.com/vpc/docs/about-private-service-connect-interfaces) can be configured via the `network_attached_interfaces` variable, which is a simple list of network attachment ids, one per interface. PSC interfaces will be defined after regular interfaces.

```hcl

# create the network attachment from a service project
module "net-attachment" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  network_attachments = {
    svc-0 = {
      subnet_self_link      = module.vpc.subnet_self_links["${var.region}/ipv6-internal"]
      producer_accept_lists = [var.project_id]
    }
  }
}

module "vm-psc-interface" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "vm-internal-ip"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  network_attached_interfaces = [
    module.net-attachment.network_attachment_ids["svc-0"]
  ]
}
# tftest fixtures=fixtures/net-vpc-ipv6.tf e2e
```

### Metadata

You can define labels and custom metadata values. Metadata can be leveraged, for example, to define a custom startup script.

```hcl
module "vm-metadata-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "nginx-server"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  labels = {
    env    = "dev"
    system = "crm"
  }
  metadata = {
    startup-script = <<-EOF
      #! /bin/bash
      apt-get update
      apt-get install -y nginx
    EOF
  }
  service_account = {
    auto_create = true
  }
}
# tftest inventory=metadata.yaml e2e
```

### IAM

Like most modules, you can assign IAM roles to the instance using the `iam` variable.

```hcl
module "vm-iam-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "webserver"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  iam = {
    "roles/compute.instanceAdmin" = [
      "group:${var.group_email}",
    ]
  }
}
# tftest inventory=iam.yaml e2e

```

### Spot VM

[Spot VMs](https://cloud.google.com/compute/docs/instances/spot) are ephemeral compute instances suitable for batch jobs and fault-tolerant workloads. Spot VMs provide new features that [preemptible instances](https://cloud.google.com/compute/docs/instances/preemptible) do not support, such as the absence of a maximum runtime.

```hcl
module "spot-vm-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test"
  scheduling_config = {
    provisioning_model = "SPOT"
    termination_action = "STOP"
  }
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
}
# tftest inventory=spot.yaml e2e
```

### Confidential compute

You can enable confidential compute with the `confidential_compute` variable, which can be used for standalone instances or for instance templates.

```hcl
module "vm-confidential-example" {
  source               = "./fabric/modules/compute-vm"
  project_id           = var.project_id
  zone                 = "${var.region}-b"
  name                 = "confidential-vm"
  confidential_compute = "SEV"
  machine_type         = "n2d-standard-2"
  boot_disk = {
    source = {
      image = "projects/debian-cloud/global/images/family/debian-12"
    }
  }
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
}

module "template-confidential-example" {
  source               = "./fabric/modules/compute-vm"
  project_id           = var.project_id
  zone                 = "${var.region}-b"
  name                 = "confidential-template"
  confidential_compute = "SEV"
  create_template      = {}
  machine_type         = "n2d-standard-2"
  boot_disk = {
    source = {
      image = "projects/debian-cloud/global/images/family/debian-12"
    }
  }
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
}

# tftest inventory=confidential.yaml e2e
```

### Disk encryption with Cloud KMS

#### External keys

This example shows how to control disk encryption via the the `encryption` variable, in this case the self link to a KMS CryptoKey that will be used to encrypt boot and attached disk. Managing the key with the `../kms` module is of course possible, but is not shown here.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  name            = "gce"
  billing_account = var.billing_account_id
  prefix          = var.prefix
  parent          = var.folder_id
  services = [
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
  ]
}

module "kms" {
  source     = "./fabric/modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = var.region
    name     = "${var.prefix}-keyring"
  }
  keys = {
    "key-regional" = {
    }
  }
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      module.project.service_agents.compute.iam_email
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
}

module "kms-vm-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = module.project.project_id
  zone       = "${var.region}-b"
  name       = "kms-test"
  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/production"]
  }]
  attached_disks = {
    attached-disk = {}
  }
  service_account = {
    auto_create = true
  }
  encryption = {
    encrypt_boot      = true
    kms_key_self_link = module.kms.keys.key-regional.id
  }
}
# tftest inventory=cmek.yaml e2e
```

#### KMS Autokey

For KMS Autokey to be used the [project needs to be enabled](https://docs.cloud.google.com/kms/docs/enable-autokey) and the principal running Terraform needs to have the `roles/cloudkms.autokeyUser` on the Autokey project.

```hcl
module "autokey-vm-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = "myproject"
  zone       = "europe-west8-b"
  name       = "kms-test"
  network_interfaces = [{
    network    = "projects/myhost/global/networks/dev-spoke-0"
    subnetwork = "projects/myhost/regions/europe-west8/subnetworks/gce"
  }]
  attached_disks = {
    attached-disk = {}
  }
  service_account = {
    auto_create = true
  }
  kms_autokeys = {
    default = {}
  }
  encryption = {
    encrypt_boot      = true
    kms_key_self_link = "$kms_keys:autokeys/default"
  }
}
# tftest modules=1 resources=4
```

### Advanced machine features

Advanced machine features can be configured via the `machine_features_config` variable.

```hcl
module "simple-vm-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  machine_features_config = {
    enable_nested_virtualization = true
    enable_turbo_mode            = true
    threads_per_core             = 2
  }
}
# tftest modules=1 resources=1
```

### Instance template

#### Global template

This example shows how to use the module to manage an instance template that defines an additional attached disk for each instance, and overrides defaults for the boot disk image and service account. Instance templates are created global by default.

```hcl
module "cos-test" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  boot_disk = {
    source = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }
  attached_disks = {
    disk-0 = {}
  }
  service_account = {
    email = module.iam-service-account.email
  }
  create_template = {}
}
# tftest inventory=template.yaml fixtures=fixtures/iam-service-account.tf e2e
```

#### Regional template

A regional template can be created by setting `var.create_template.regional`.

```hcl
module "cos-test" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  boot_disk = {
    source = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }
  attached_disks = {
    disk-0 = {
      auto_delete = true
    }
  }
  service_account = {
    email = module.iam-service-account.email
  }
  create_template = {
    regional = true
  }
}
# tftest inventory=template-regional.yaml fixtures=fixtures/iam-service-account.tf
```

### Instance group

If an instance group is needed when operating in instance mode, simply set the `group` variable to a non null map. The map can contain named port declarations, or be empty if named ports are not needed.

```hcl
locals {
  cloud_config = "my cloud config"
}

module "instance-group" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "ilb-test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  boot_disk = {
    source = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }
  service_account = {
    email  = var.service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  metadata = {
    user-data = local.cloud_config
  }
  group = { named_ports = {} }
}
# tftest inventory=group.yaml e2e
```

You can also use the `group` variable to add the instance to an existing unmanaged instance group by providing the group's self link or ID in the `membership` field.

```hcl
module "instance-group-membership" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "ilb-test-member"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  group = {
    membership = "my-existing-group-id"
  }
}
# tftest inventory=group-membership.yaml
```

### Instance Schedule and Resource Policies

One instance start and stop schedule can be defined via the `instance_schedule` variable. Note that this requires [additional permissions on Compute Engine Service Agent](https://cloud.google.com/compute/docs/instances/schedule-instance-start-stop#service_agent_required_roles). Already defined resource policies can be set via the `resource_policies` variable.

```hcl
module "instance" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "schedule-test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  boot_disk = {
    source = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }
  resource_policies = [
    "projects/${var.project_id}/regions/${var.region}/resourcePolicies/test"
  ]
}
# tftest inventory=instance-schedule-id.yaml
```

To create a new policy set its configuration in the `instance_schedule` variable. When removing the policy follow a two-step process by first setting `active = false` in the schedule configuration, which will unattach the policy, then removing the variable so the policy is destroyed.

```hcl
module "project" {
  source = "./fabric/modules/project"
  name   = var.project_id
  project_reuse = {
    use_data_source = false
    attributes = {
      name             = var.project_id
      number           = var.project_number
      services_enabled = ["compute.googleapis.com"]
    }
  }
  iam_bindings_additive = {
    compute-admin-service-agent = {
      member = module.project.service_agents["compute"].iam_email
      role   = "roles/compute.instanceAdmin.v1"
    }
  }
}

module "instance" {
  source     = "./fabric/modules/compute-vm"
  project_id = module.project.project_id
  zone       = "${var.region}-b"
  name       = "schedule-test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  boot_disk = {
    source = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }
  instance_schedule = {
    vm_start = "0 8 * * *"
    vm_stop  = "0 17 * * *"
  }
  depends_on = [module.project] # ensure that grants are complete before creating schedule / instance
}
# tftest inventory=instance-schedule-create.yaml e2e
```

### Snapshot Schedules

Snapshot policies can be attached to disks with optional creation managed by the module.

```hcl
module "instance" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "schedule-test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  boot_disk = {
    source = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
    snapshot_schedule = ["boot"]
  }
  attached_disks = {
    disk-1 = {
      initialize_params = {
        replica_zone = "${var.region}-c"
      }
      snapshot_schedule = ["data"]
    }
  }
  snapshot_schedules = {
    boot = {
      schedule = {
        hourly = {
          hours_in_cycle = 1
          start_time     = "03:00"
        }
      }
    }
    data = {
      schedule = {
        daily = {
          days_in_cycle = 1
          start_time    = "04:00"
        }
      }
    }
  }
}
# tftest inventory=snapshot-schedule-create.yaml e2e
```

### Resource Manager Tags

Resource manager tags bindings for use in IAM or org policy conditions are supported via three different variables:

- `network_tag_bindings` associates tags to instances after creation, and is meant for use with network firewall policies
- `tag_bindings` associates tags to instances and disks after creation, and is meant for use with IAM or organization policy conditions
- `tag_bindings_immutable` associates tags to instances and disks during the instance or template creation flow; these bindings are immutable and changes trigger resource recreation

The non-immutable variables follow our usual interface for tag bindings, and support specifying a map with arbitrary keys mapping to tag key or value ids. To prevent a provider permadiff also pass in the project number in the `project_number` variable.

The immutable variable uses a different format enforced by the Compute API, where keys need to be tag key ids, and values tag value ids.

This is an example of setting non-immutable tag bindings:

```hcl
module "simple-vm-example" {
  source         = "./fabric/modules/compute-vm"
  project_id     = var.project_id
  project_number = 12345678
  zone           = "${var.region}-b"
  name           = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  tag_bindings = {
    dev = "tagValues/1234567890"
  }
}
# tftest modules=1 resources=2
```

This example uses immutable tag bindings, and will trigger recreation if those are changed.

```hcl
module "simple-vm-example" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  tag_bindings_immutable = {
    "tagKeys/1234567890" = "tagValues/7890123456"
  }
}
# tftest inventory=tag-bindings.yaml
```

### Sole Tenancy

You can add node affinities (and anti-affinity) configurations to allocate the VM on sole tenant nodes.

```hcl
module "sole-tenancy" {
  source       = "./fabric/modules/compute-vm"
  project_id   = var.project_id
  zone         = "${var.region}-b"
  machine_type = "n1-standard-1"
  name         = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  scheduling_config = {
    node_affinities = {
      workload = {
        values = ["frontend"]
      }
      cpu = {
        in     = false
        values = ["c3"]
      }
    }
  }
}
# tftest inventory=sole-tenancy.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L358) | Instance name. | <code>string</code> | ✓ |  |
| [network_interfaces](variables.tf#L370) | Network interfaces configuration. Use self links for Shared VPC, set addresses to null if not needed. | <code>list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L410) | Project id. | <code>string</code> | ✓ |  |
| [zone](variables.tf#L567) | Compute zone. | <code>string</code> | ✓ |  |
| [attached_disks](variables.tf#L17) | Additional disks. Source type is one of 'image' (zonal disks in vms and template), 'snapshot' (vm), 'existing', and null. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [boot_disk](variables.tf#L57) | Boot disk properties. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [can_ip_forward](variables.tf#L114) | Enable IP forwarding. | <code>bool</code> |  | <code>false</code> |
| [confidential_compute](variables.tf#L120) | Confidential Compute configuration. Set to 'SEV' or 'SEV_SNP' to enable. | <code>string</code> |  | <code>null</code> |
| [context](variables.tf#L130) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [create_template](variables.tf#L151) | Create instance template instead of instances. Defaults to a global template. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [description](variables.tf#L160) | Description of a Compute Instance. | <code>string</code> |  | <code>&#34;Managed by the compute-vm Terraform module.&#34;</code> |
| [enable_display](variables.tf#L166) | Enable virtual display on the instances. | <code>bool</code> |  | <code>false</code> |
| [encryption](variables.tf#L172) | Encryption options. Only one of kms_key_self_link and disk_encryption_key_raw may be set. If needed, you can specify to encrypt or not the boot disk. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [gpu](variables.tf#L183) | GPU information. Based on https://cloud.google.com/compute/docs/gpus. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [group](variables.tf#L218) | Instance group configuration. Set 'named_ports' to create a new unmanaged instance group, or provide an existing group self_link/id in 'membership' to join one. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [hostname](variables.tf#L227) | Instance FQDN name. | <code>string</code> |  | <code>null</code> |
| [iam](variables.tf#L233) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [instance_schedule](variables.tf#L239) | Assign or create and assign an instance schedule policy. Set active to null to detach a policy from vm before destroying. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [kms_autokeys](variables.tf#L263) | KMS Autokey key handles. If location is not specified it will be inferred from the zone. Key handle names will be added to the kms_keys context with an `autokeys/` prefix. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L281) | Instance labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [lifecycle_config](variables.tf#L287) | Instance lifecycle and operational configurations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [machine_features_config](variables.tf#L309) | Machine-level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [machine_type](variables.tf#L333) | Machine type. | <code>string</code> |  | <code>&#34;e2-micro&#34;</code> |
| [metadata](variables.tf#L339) | Instance metadata. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [metadata_startup_script](variables.tf#L345) | Instance startup script. Will trigger recreation on change, even after importing. | <code>string</code> |  | <code>null</code> |
| [min_cpu_platform](variables.tf#L352) | Minimum CPU platform. | <code>string</code> |  | <code>null</code> |
| [network_attached_interfaces](variables.tf#L363) | Network interfaces using network attachments. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [network_performance_tier](variables.tf#L393) | Network performance total egress bandwidth tier. | <code>string</code> |  | <code>null</code> |
| [network_tag_bindings](variables.tf#L403) | Resource manager tag bindings in arbitrary key => tag key or value id format. Set on both the instance only for networking purposes, and modifiable without impacting the main resource lifecycle. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [project_number](variables.tf#L415) | Project number. Used in tag bindings to avoid a permadiff. | <code>string</code> |  | <code>null</code> |
| [resource_policies](variables.tf#L421) | Resource policies to attach to the instance or template. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [scheduling_config](variables.tf#L428) | Scheduling configuration for the instance. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [scratch_disks](variables.tf#L463) | Scratch disks configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [service_account](variables.tf#L476) | Service account email and scopes. If email is null, the default Compute service account will be used unless auto_create is true, in which case a service account will be created. Set the variable to null to avoid attaching a service account. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [shielded_config](variables.tf#L487) | Shielded VM configuration of the instances. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [snapshot_schedules](variables.tf#L497) | Snapshot schedule resource policies that can be attached to disks. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [tag_bindings](variables.tf#L540) | Resource manager tag bindings in arbitrary key => tag key or value id format. Set on both the instance and zonal disks, and modifiable without impacting the main resource lifecycle. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [tag_bindings_immutable](variables.tf#L547) | Immutable resource manager tag bindings, in tagKeys/id => tagValues/id format. These are set on the instance or instance template at creation time, and trigger recreation if changed. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [tags](variables.tf#L561) | Instance network tags for firewall rule targets. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [external_ip](outputs.tf#L17) | Instance main interface external IP addresses. |  |
| [group](outputs.tf#L26) | Instance group resource. |  |
| [id](outputs.tf#L31) | Fully qualified instance id. |  |
| [instance](outputs.tf#L36) | Instance resource. | ✓ |
| [internal_ip](outputs.tf#L42) | Instance main interface internal IP address. |  |
| [internal_ips](outputs.tf#L50) | Instance interfaces internal IP addresses. |  |
| [login_command](outputs.tf#L58) | Command to SSH into the machine. |  |
| [self_link](outputs.tf#L63) | Instance self links. |  |
| [service_account](outputs.tf#L68) | Service account resource. |  |
| [service_account_email](outputs.tf#L73) | Service account email. |  |
| [service_account_iam_email](outputs.tf#L78) | Service account email. |  |
| [template](outputs.tf#L87) | Template resource. |  |
| [template_name](outputs.tf#L96) | Template name. |  |

## Fixtures

- [iam-service-account.tf](../../tests/fixtures/iam-service-account.tf)
- [net-vpc-ipv6.tf](../../tests/fixtures/net-vpc-ipv6.tf)
<!-- END TFDOC -->
