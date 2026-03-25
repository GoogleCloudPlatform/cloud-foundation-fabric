# Refactor compute-vm module variables and add new resource attributes

**authors:** [Ludo](https://github.com/ludoo) [Wiktor](https://github.com/wiktorn) \
**date:** Mar 23, 2026

<!-- BEGIN TOC -->
- [Status](#status)
- [Context](#context)
- [Decision](#decision)
  - [1. List vs. Map for Interfaces and Disks](#1-list-vs-map-for-interfaces-and-disks)
  - [2. Disk Refactoring Strategy](#2-disk-refactoring-strategy)
    - [Disambiguating Disk "Names"](#disambiguating-disk-names)
    - [Unifying `boot_disk` and `attached_disks` Structures](#unifying-boot_disk-and-attached_disks-structures)
    - [Polymorphic `source` Object](#polymorphic-source-object)
    - [Example Usage: Polymorphic Disks](#example-usage-polymorphic-disks)
      - [1. Boot Disk Examples](#1-boot-disk-examples)
      - [2. Attached Disks Examples](#2-attached-disks-examples)
  - [3. Feature and Options Grouping Strategy](#3-feature-and-options-grouping-strategy)
    - [Proposed Groupings and Type Definitions](#proposed-groupings-and-type-definitions)
      - [1. `machine_type` / Machine Configuration](#1-machine_type-machine-configuration)
      - [2. `scheduling_config` (Replaces parts of `options`)](#2-scheduling_config-replaces-parts-of-options)
      - [3. `confidential_compute` (Updating to support SEV-SNP)](#3-confidential_compute-updating-to-support-sev-snp)
      - [4. `shielded_config`](#4-shielded_config)
      - [5. `network_interfaces` Enhancements](#5-network_interfaces-enhancements)
      - [6. `network_performance_tier` (NEW)](#6-network_performance_tier-new)
      - [7. `lifecycle_config` (Replaces residual `options`)](#7-lifecycle_config-replaces-residual-options)
  - [4. Instance Groups and Policies](#4-instance-groups-and-policies)
    - [Instance Groups (`group`)](#instance-groups-group)
    - [Resource Policies (Snapshots and Schedules)](#resource-policies-snapshots-and-schedules)
  - [5. Templates (`create_template`) Strategy](#5-templates-create_template-strategy)
    - [Key Refactoring Points for Templates](#key-refactoring-points-for-templates)
- [TODO](#todo)
<!-- END TOC -->

## Status

Draft

## Context

The `compute-vm` module currently uses variable schemas that diverge from the modern standards adopted by newer Cloud Foundation Fabric modules. The current design of `boot_disk` and `attached_disks` uses different schemas, lacks polymorphic source structures, and utilizes lists instead of maps, causing `for_each` stability issues. Furthermore, several modern `google_compute_instance` attributes (e.g., `queue_count`, `network_performance_config`, advanced scheduling, SEV-SNP) are missing.

## Decision

### 1. List vs. Map for Interfaces and Disks

- **Network Interfaces:** The order of network interfaces is critical in GCP VMs (e.g., `nic0` is the primary interface, `nic1` is secondary, etc.). Terraform's `google_compute_instance` resource processes the `network_interface` blocks in the order they are defined. Using a `map` would lose this explicit ordering (since map keys are sorted alphabetically in Terraform), making it impossible to guarantee which interface becomes `nic0`. Therefore, `network_interfaces` **must remain a list**.
- **Attached Disks:** While disks also have an implicit order when attached, their identity is more strongly tied to their `device_name` or `name` rather than their strict numerical index. The current approach of using a list and generating keys based on index (`"disk-${i}"`) causes issues with `for_each` loops (like in `google_compute_disk_resource_policy_attachment`) when dynamic values or conditional creations are involved, leading to the "value of count cannot be computed" or "invalid for_each argument" errors. Switching `attached_disks` to a `map(object({...}))` where the key is the logical name or `device_name` solves these `for_each` stability issues and aligns with modern Fabric patterns.

### 2. Disk Refactoring Strategy

#### Disambiguating Disk "Names"

Disks in GCP and Terraform have several identifiers which often cause confusion. We will explicitly disambiguate them as follows:

1. **Map Key (The Identifier):** In the new `attached_disks` map, the key itself will act as the primary logical identifier for the disk within the module's Terraform state.
2. **Device Name (`device_name`):** This is the name exposed to the Guest OS (e.g., visible in `/dev/disk/by-id/google-<device_name>`).
    - *Rule:* We will default the `device_name` to the **Map Key**. Users can override it explicitly if needed, but the map key provides a safe, predictable default.
3. **Resource Name (`name`):** This is the actual name of the `google_compute_disk` resource created in the GCP API.
    - *Rule:* To ensure uniqueness across a project, we will default the resource name to `${var.name}-${each.key}` (the VM name hyphenated with the Map Key). Users can provide an explicit `name` attribute to override this (e.g., when attaching an existing disk or requiring a specific naming convention).

#### Unifying `boot_disk` and `attached_disks` Structures

Currently, `boot_disk` uses an `initialize_params` block (mirroring Terraform's native syntax), while `attached_disks` uses an `options` block and keeps `size` at the top level. We will align them to use a consistent schema:

- **Adopt `initialize_params`:** Both `boot_disk` and `attached_disks` will use an `initialize_params` block for creation-specific attributes (size, type, image, architecture, provisioned iops/throughput). This clearly separates attributes used for *creating* a disk from attributes used for *attaching* a disk.
- **Top-level attributes:** Attributes relevant to the attachment or lifecycle (e.g., `source`, `auto_delete`, `mode`) will live at the top level of the disk object.
- **Source Type Handling:** For `attached_disks`, we will keep a mechanism to distinguish between creating from an image/snapshot vs. attaching an existing disk (e.g., keeping `source_type` or inferring it from the presence of `initialize_params` vs `source`).

#### Polymorphic `source` Object

To eliminate the confusing `source` (string) and `source_type` (string) variables, we will use a polymorphic `source` object. This pattern ensures mutual exclusivity and clearly defines the origin of the disk.

**Type Definition:**

```hcl
source = optional(object({
  attach   = optional(string)
  disk     = optional(string)
  image    = optional(string)
  snapshot = optional(string)
}))
```

**Validation:**
A validation rule will ensure that if `source` is provided, exactly one of its attributes is non-null. If `source` is omitted entirely (for attached disks), it implies creating a blank disk.

**Updated Variable Structures:**

```hcl
variable "boot_disk" {
  type = object({
    auto_delete       = optional(bool, true)
    snapshot_schedule = optional(list(string))
    initialize_params = optional(object({
      architecture = optional(string)
      size         = optional(number, 10)
      type         = optional(string, "pd-balanced")
      hyperdisk = optional(object({
        provisioned_iops       = optional(number)
        provisioned_throughput = optional(number) # in MiB/s
        storage_pool           = optional(string)
      }), {})
    }), {})
    source = optional(object({
      attach   = optional(string)
      disk     = optional(string)
      image    = optional(string)
      snapshot = optional(string)
    }), { image = "projects/debian-cloud/global/images/family/debian-11" })
    use_independent_disk = optional(object({
      name = optional(string)
    }))
  })
}

variable "attached_disks" {
  type = map(object({
    auto_delete       = optional(bool, false)
    device_name       = optional(string)
    mode              = optional(string, "READ_WRITE")
    name              = optional(string)
    initialize_params = optional(object({
      architecture = optional(string)
      replica_zone = optional(string)
      size         = optional(number, 10)
      type         = optional(string, "pd-balanced")
      hyperdisk = optional(object({
        provisioned_iops       = optional(number)
        provisioned_throughput = optional(number) # in MiB/s
        storage_pool           = optional(string)
      }), {})
    }), {})
    snapshot_schedule = optional(list(string))
    source = optional(object({
      attach   = optional(string)
      image    = optional(string)
      snapshot = optional(string)
    }), {})
  }))
}
```

#### Example Usage: Polymorphic Disks

Here is how the proposed `boot_disk` and `attached_disks` variables look in practice using the polymorphic `source` object.

##### 1. Boot Disk Examples

```hcl
# Default boot disk (from image)
boot_disk = {
  auto_delete = true
  source = {
    image = "projects/debian-cloud/global/images/family/debian-11"
  }
  initialize_params = {
    size = 20
    type = "pd-ssd"
  }
}

# Booting from an existing attached disk
boot_disk = {
  auto_delete = false
  source = {
    attach = "projects/my-project/zones/europe-west1-b/disks/my-existing-boot-disk"
  }
  # initialize_params are omitted/ignored when attaching
}
```

##### 2. Attached Disks Examples

```hcl
attached_disks = {
  # 1. Create a blank disk
  # The map key ("data-disk") is the primary identifier.
  data-disk = {
    auto_delete = false
    mode        = "READ_WRITE"
    initialize_params = {
      size = 100
      type = "pd-balanced"
    }
    # source is omitted entirely
  }

  # 2. Create a disk from a snapshot
  restored-data = {
    source = {
      snapshot = "projects/my-project/global/snapshots/my-snapshot"
    }
    initialize_params = {
      size = 500
      type = "pd-ssd"
    }
  }

  # 3. Attach an existing disk (overriding defaults)
  existing-backup = {
    device_name = "backup-mount" # Explicitly set device name for OS
    mode        = "READ_ONLY"
    source = {
      attach = "projects/my-project/zones/europe-west1-b/disks/my-existing-disk"
    }
  }
}
```

### 3. Feature and Options Grouping Strategy

Currently, `compute-vm` has a mix of top-level boolean toggles (`confidential_compute`, `can_ip_forward`, `enable_display`) and a catch-all `options` variable that houses `advanced_machine_features`, scheduling/spot configurations, and operational toggles.

To align with modern Fabric patterns, we will decompose these into logical `*_config` objects and structured variables. **Crucially, almost all string field that maps to an API enum (e.g., `provisioning_model`, `maintenance_interval`) will include strict Terraform validation rules.** `nic_type` will be an exception from this rule as the valid values depend on machine\_type and there might be new types introduced in the future.

#### Proposed Groupings and Type Definitions

##### 1. `machine_type` / Machine Configuration

Currently named `instance_type`, we will rename it to `machine_type` to align with GCP console and gcloud terminology. `min_cpu_platform` remains top-level. `advanced_machine_features` will be extracted from `options` into its own top-level block or kept flat.

##### 2. `scheduling_config` (Replaces parts of `options`)

The `google_compute_instance.scheduling` block in Terraform handles spot instances, maintenance, and run durations. We will extract these from the current `options` variable into a dedicated `scheduling_config` object and add the missing modern attributes.

```hcl
variable "scheduling_config" {
  description = "Scheduling configuration for the instance."
  type = object({
    automatic_restart           = optional(bool) # Defaults to !spot
    instance_termination_action = optional(string)
    local_ssd_recovery_timeout  = optional(object({ # NEW
      nanos   = optional(number)
      seconds = number
    }))
    maintenance_interval        = optional(string) # NEW
    max_run_duration = optional(object({
      nanos   = optional(number)
      seconds = number
    }))
    min_node_cpus               = optional(number) # NEW
    node_affinities = optional(map(object({
      values = list(string)
      in     = optional(bool, true)
    })), {})
    on_host_maintenance         = optional(string) # Defaults to MIGRATE or TERMINATE based on GPU/Spot
    provisioning_model          = optional(string) # "SPOT" or "STANDARD"
  })
  default = {}
}
```

*Example Usage:*

```hcl
scheduling_config = {
  provisioning_model          = "SPOT"
  instance_termination_action = "STOP"
  maintenance_interval        = "PERIODIC"
  node_affinities = {
    "compute.googleapis.com/node-group-name" = {
      values = ["my-node-group"]
    }
  }
}
```

##### 3. `confidential_compute` (Updating to support SEV-SNP)

Currently a boolean. Since the Terraform block (`confidential_instance_config`) effectively only needs to know the type (SEV or SEV_SNP) when enabled, we will change this to a simple string to avoid a single-field object.

```hcl
variable "confidential_compute" {
  description = "Confidential Compute configuration. Set to 'SEV' or 'SEV_SNP' to enable."
  type        = string
  default     = null # If null, feature is disabled
  validation {
    condition     = var.confidential_compute == null || contains(["SEV", "SEV_SNP"], coalesce(var.confidential_compute, "-"))
    error_message = "Allowed values are 'SEV' or 'SEV_SNP'."
  }
}
```

*Example Usage:*

```hcl
confidential_compute = "SEV_SNP"
```

##### 4. `shielded_config`

Remains an object, but we ensure its type signature uses strict `optional()` defaults mirroring current behavior.

```hcl
variable "shielded_config" {
  description = "Shielded VM configuration of the instances."
  type = object({
    enable_secure_boot          = optional(bool, true)
    enable_vtpm                 = optional(bool, true)
    enable_integrity_monitoring = optional(bool, true)
  })
  default = null
}
```

*Example Usage:*

```hcl
shielded_config = {
  enable_secure_boot = true
  enable_vtpm        = false
}
```

##### 5. `network_interfaces` Enhancements

We will add the missing modern attributes directly to the existing list of objects:

- `queue_count`
- `internal_ipv6_prefix_length`

```hcl
variable "network_interfaces" {
  description = "Network interfaces configuration. Use self links for Shared VPC, set addresses to null if not needed."
  type = list(object({
    network                     = string
    subnetwork                  = string
    alias_ips                   = optional(map(string), {})
    nat                         = optional(bool, false)
    nic_type                    = optional(string)
    stack_type                  = optional(string)
    queue_count                 = optional(number) # NEW
    internal_ipv6_prefix_length = optional(number) # NEW
    addresses = optional(object({
      internal = optional(string)
      external = optional(string)
    }), null)
    network_tier = optional(string)
  }))
}
```

*Example Usage:*

```hcl
network_interfaces = [{
  network                     = "my-vpc"
  subnetwork                  = "my-subnet"
  queue_count                 = 4
  internal_ipv6_prefix_length = 96
}]
```

##### 6. `network_performance_tier` (NEW)

Since the `network_performance_config` block only contains a single field (`total_egress_bandwidth_tier`), we will implement it as a flat string variable to avoid unnecessary complex objects.

```hcl
variable "network_performance_tier" {
  description = "Network performance total egress bandwidth tier."
  type        = string
  default     = null
  validation {
    condition     = var.network_performance_tier == null || contains(["DEFAULT", "TIER_1"], coalesce(var.network_performance_tier, "-"))
    error_message = "Allowed values are 'DEFAULT' or 'TIER_1'."
  }
}
```

*Example Usage:*

```hcl
network_performance_tier = "TIER_1"
```

##### 7. `lifecycle_config` (Replaces residual `options`)

Operational toggles will be grouped into a `lifecycle_config` object. `key_revocation_action_type` dictates whether the VM stops when its CMEK is revoked, which fits well within lifecycle management.

```hcl
variable "lifecycle_config" {
  description = "Instance lifecycle and operational configurations."
  type = object({
    allow_stopping_for_update  = optional(bool, true)
    deletion_protection        = optional(bool, false)
    key_revocation_action_type = optional(string, "NONE")
    graceful_shutdown = optional(object({
      enabled           = optional(bool, false)
      max_duration_secs = optional(number)
    }))
  })
  default = {}
}
```

*Example Usage:*

```hcl
lifecycle_config = {
  deletion_protection        = true
  allow_stopping_for_update  = false
  key_revocation_action_type = "STOP"
  graceful_shutdown = {
    enabled           = true
    max_duration_secs = 60
  }
}
```

### 4. Instance Groups and Policies

#### Instance Groups (`group`)

Currently, the module can only *create* an unmanaged instance group and add the VM to it. We will expand this to support adding the VM to an *existing* unmanaged instance group using the `google_compute_instance_group_membership` resource.

To manage this cleanly, we will update the `group` variable to support both modes:

```hcl
variable "group" {
  description = "Instance group configuration. Set 'named_ports' to create a new unmanaged instance group, or provide an existing group self_link/id in 'membership' to join one."
  type = object({
    named_ports = optional(map(number))
    membership  = optional(string) # ID of an existing unmanaged group to join
  })
  default = null
}
```

*Note: If `named_ports` is provided, a new group is created. If `membership` is provided, the VM joins the specified existing group. They are mutually exclusive.*

#### Resource Policies (Snapshots and Schedules)

The module currently supports creating `snapshot_schedules` and an `instance_schedule`.

- **Snapshot Schedules:** The existing `snapshot_schedules` variable is already well-structured using modern optionals. We will retain this structure. The primary refactoring here will be updating the attachment logic (`google_compute_disk_resource_policy_attachment`) to iterate over the new `attached_disks` map instead of the old list.
- **Instance Schedule:** The `instance_schedule` variable is also well-structured using strict optionals and will be retained.
- **Placement Policies:** The existing `resource_policies` list variable already allows attaching externally created placement policies (Collocated/Spread) or other custom policies. We will keep this as-is for flexibility, as placement policies are typically shared across multiple standalone VMs.

### 5. Templates (`create_template`) Strategy

Currently, `create_template` is an object `type = object({ regional = optional(bool, false) })` that defaults to `null`. It creates either a `google_compute_instance_template` or `google_compute_region_instance_template` depending on the `regional` flag.

While this pattern is somewhat unusual in the Fabric codebase, we will keep the `create_template` variable structure but ensure it is strictly integrated with the new disk schemas.

#### Key Refactoring Points for Templates

1. **Disk Schema Alignment:** The `template.tf` file currently maps the old `options` block to the template's `disk` block. This mapping will be updated to reflect the new `initialize_params` and polymorphic `source` blocks.
    - *Constraint:* Templates do not allow specifying `source_image` alongside `disk_name` or `disk_size_gb` in the same way standalone instances do (some fields are mutually exclusive).
    - *Solution Map:*
        - `source.image` -> `source_image`
        - `source.snapshot` -> `source_snapshot`
        - `source.attach` -> `source` (attaching an existing disk)
        - `source == null` -> creates a blank disk
2. **Attribute Parity:** All newly refactored attributes (`network_performance_tier`, `scheduling_config`, updated `confidential_compute`, and network interface enhancements) will be mapped directly into the respective blocks within both regional and global template resources.
3. **Tags and Labels:** No architectural change here, but we will ensure that `tag_bindings_immutable` continues to map correctly to `resource_manager_tags`.

## TODO

Example tests will be adapted and run as part of each task iteration.

- [x] **Task 1:** Update `variables.tf` to implement the new disk structures (`boot_disk` and `attached_disks`), polymorphic `source`, and disambiguate disk names.
- [ ] **Task 2:** Refactor `variables.tf` for feature grouping: rename `instance_type` to `machine_type`, add `scheduling_config`, `lifecycle_config`, `network_performance_tier`, and update `confidential_compute`.
- [ ] **Task 3:** Add new attributes to `network_interfaces` (`queue_count`, `internal_ipv6_prefix_length`).
- [ ] **Task 4:** Split `template.tf` into `template-zonal.tf` and `template-regional.tf`, extract `instance.tf` from `main.tf` to allow easy comparison of feature coverage.
- [ ] **Task 5:** Expand the `group` variable to support the `membership` attribute.
- [ ] **Task 6:** Update `instance.tf` and `outputs.tf` to consume the new variables (standalone VM implementation).
- [ ] **Task 7:** Update `tags.tf` and `resource-policies.tf` to work with the new `attached_disks` map instead of a list.
- [ ] **Task 8:** Update `template-zonal.tf` and `template-regional.tf` to align with the new disk schemas and map the new feature attributes.
- [ ] **Task 9:** Run integration tests and regenerate documentation (`python3 tools/tfdoc.py` and YAML test files updates).
- [ ] **Task 10:** Assess if disk-level encryption key overrides make sense, and if so implement them.

## Addendum: Missing Disk Attributes

Based on a review of the latest `terraform-provider-google` documentation for `google_compute_disk`, `google_compute_region_disk`, and `google_compute_instance` disk attachments, the following attributes are currently missing from the proposed disk type definitions and should be considered for inclusion:

### 1. Metadata and Organization

* **`description`** `(string)`: An optional description of the disk resource.
- **`labels`** `(map(string))`: Key/value pairs to label the disk.
- **`params`** / **`resource_manager_tags`** `(map(string))`: Resource manager tags to be bound to the disk.
- **`licenses`** `(list(string))`: Applicable license URIs to apply to the disk.

### 2. Encryption and Security

* **`disk_encryption_key`** `(object)`: Used to encrypt the disk with a customer-supplied (CSEK) or customer-managed (CMEK) key.
- **`source_image_encryption_key`** `(object)`: Required to decrypt the source image if it is protected by a CSEK/CMEK.
- **`source_snapshot_encryption_key`** `(object)`: Required to decrypt the source snapshot if it is protected by a CSEK/CMEK.
- **`enable_confidential_compute`** `(bool)`: Whether the disk uses confidential compute mode (supported on certain Hyperdisk SKUs).
- **`disk_encryption_key_raw`** / **`kms_key_self_link`**: Required on the `attached_disk` block of `google_compute_instance` to mount an existing encrypted disk.

### 3. Advanced Disk Features & Hyperdisk

* **`access_mode`** `(string)`: Specifically for Hyperdisks (e.g., `READ_WRITE_SINGLE`, `READ_WRITE_MANY`, `READ_ONLY_SINGLE`).
- **`multi_writer`** `(bool)`: Indicates whether a persistent disk can be read/write attached to more than one instance.
- **`physical_block_size_bytes`** `(number)`: Allows specifying physical block size (usually `4096` or `16384`).
- **`guest_os_features`** `(list(object))`: Features to enable on the guest OS (e.g., `UEFI_COMPATIBLE`, `SECURE_BOOT`, `MULTI_IP_SUBNET`).
- **`async_primary_disk`** `(object)`: Primary disk configuration for asynchronous disk replication.

### 4. Source Creation Options

* **`source_disk`** `(string)`: Allows creating a new disk by cloning an existing `google_compute_disk` (supported by both zonal and regional disks).
- **`source_instant_snapshot`** `(string)`: Allows creating a disk from a Google Compute instant snapshot.
- **`source_storage_object`** `(string)`: Allows creating a disk directly from a GCS URI tarball/vmdk.
- **`erase_windows_vss_signature`** `(bool)`: Specifies whether the disk restored from a source snapshot should erase the Windows-specific VSS signature.
- **Note on Regional Disks:** `google_compute_region_disk` does not support initialization directly from an `image`. The `source.image` attribute will only work for zonal disks.

### 5. Disk Lifecycle

* **`create_snapshot_before_destroy`** `(bool)`: If `true`, creates a snapshot of the disk before Terraform destroys it.
- **`create_snapshot_before_destroy_prefix`** `(string)`: A custom prefix for the snapshot name created prior to destruction.
