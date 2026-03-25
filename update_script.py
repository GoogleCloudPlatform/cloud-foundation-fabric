import re

with open("adrs/modules/20260323-compute-vm-refactoring.md", "r") as f:
    content = f.read()

# Replace Type Definition and Updated Variable Structures
old_block = """**Type Definition:**

```hcl
source = optional(object({
  image    = optional(string)
  snapshot = optional(string)
  attach   = optional(string)
}))
```

**Validation:**
A validation rule will ensure that if `source` is provided, exactly one of its attributes (`image`, `snapshot`, or `attach`) is non-null. If `source` is omitted entirely (for attached disks), it implies creating a blank disk.

**Updated Variable Structures:**

```hcl
variable "boot_disk" {
  type = object({
    auto_delete = optional(bool, true)
    device_name = optional(string)
    initialize_params = optional(object({
      size                   = optional(number, 10)
      type                   = optional(string, "pd-balanced")
      provisioned_iops       = optional(number)
      provisioned_throughput = optional(number)
    }), {})
    source = optional(object({
      image    = optional(string)
      snapshot = optional(string)
      attach   = optional(string)
    }), { image = "projects/debian-cloud/global/images/family/debian-11" })
  })
}

variable "attached_disks" {
  type = map(object({
    device_name = optional(string)
    auto_delete = optional(bool, false)
    mode        = optional(string, "READ_WRITE")
    initialize_params = optional(object({
      size                   = optional(number)
      type                   = optional(string, "pd-balanced")
      provisioned_iops       = optional(number)
      provisioned_throughput = optional(number)
    }), {})
    source = optional(object({
      image    = optional(string)
      snapshot = optional(string)
      attach   = optional(string)
    }))
  }))
}
```"""

new_block = """**Type Definition:**

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
```"""

content = content.replace(old_block, new_block)

# Replace "## Plan" with "## TODO" and checkboxes
old_plan = """## Plan

Example tests will be adapted and run as part of each task iteration.

1. **Task 1:** Update `variables.tf` to implement the new disk structures (`boot_disk` and `attached_disks`), polymorphic `source`, and disambiguate disk names.
2. **Task 2:** Refactor `variables.tf` for feature grouping: rename `instance_type` to `machine_type`, add `scheduling_config`, `lifecycle_config`, `network_performance_tier`, and update `confidential_compute`.
3. **Task 3:** Add new attributes to `network_interfaces` (`queue_count`, `internal_ipv6_prefix_length`).
4. **Task 4:** Split `template.tf` into `template-zonal.tf` and `template-regional.tf`, extract `instance.tf` from `main.tf` to allow easy comparison of feature coverage.
5. **Task 5:** Expand the `group` variable to support the `membership` attribute.
6. **Task 6:** Update `instance.tf` and `outputs.tf` to consume the new variables (standalone VM implementation).
7. **Task 7:** Update `tags.tf` and `resource-policies.tf` to work with the new `attached_disks` map instead of a list.
8. **Task 8:** Update `template-zonal.tf` and `template-regional.tf` to align with the new disk schemas and map the new feature attributes.
9. **Task 9:** Run integration tests and regenerate documentation (`python3 tools/tfdoc.py` and YAML test files updates).
10. **Task 10.** Assess if disk-level encryption key overrides make sense, and if so implement them."""

new_plan = """## TODO

Example tests will be adapted and run as part of each task iteration.

- [x] **Task 1:** Update `variables.tf` to implement the new disk structures (`boot_disk` and `attached_disks`), polymorphic `source`, and disambiguate disk names.
- [ ] **Task 2:** Refactor `variables.tf` for feature grouping: rename `instance_type` to `machine_type`, add `scheduling_config`, `lifecycle_config`, `network_performance_tier`, and update `confidential_compute`.
- [ ] **Task 3:** Add new attributes to `network_interfaces` (`queue_count`, `internal_ipv6_prefix_length`).
- [x] **Task 4:** Split `template.tf` into `template-zonal.tf` and `template-regional.tf`, extract `instance.tf` from `main.tf` to allow easy comparison of feature coverage.
- [ ] **Task 5:** Expand the `group` variable to support the `membership` attribute.
- [x] **Task 6:** Update `instance.tf` and `outputs.tf` to consume the new variables (standalone VM implementation).
- [x] **Task 7:** Update `tags.tf` and `resource-policies.tf` to work with the new `attached_disks` map instead of a list.
- [x] **Task 8:** Update `template-zonal.tf` and `template-regional.tf` to align with the new disk schemas and map the new feature attributes.
- [x] **Task 9:** Run integration tests and regenerate documentation (`python3 tools/tfdoc.py` and YAML test files updates).
- [ ] **Task 10:** Assess if disk-level encryption key overrides make sense, and if so implement them."""

# Wait, looking at the repo:
# main.tf is not fully split yet since instance.tf is created but template-zonal.tf and template-regional.tf do not exist, they are still combined in template.tf?
# Oh wait, let's look at `ls -la modules/compute-vm/` again:
# -rw-r-----  1 ludomagno primarygroup  4625 Mar 25 11:57 disks.tf
# -rw-r-----  1 ludomagno primarygroup  8824 Mar 25 11:54 instance.tf
# -rw-r-----  1 ludomagno primarygroup  3942 Mar 25 11:40 main.tf
# -rw-r-----  1 ludomagno primarygroup 15892 Mar 25 12:02 template.tf
# So Task 4 is NOT fully done? Let me just mark Task 1 done, because the user said "I only worked on the boot_disk and attached_disks variable so far." I will mark Task 1 done and the rest unchecked.

new_plan2 = """## TODO

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
- [ ] **Task 10:** Assess if disk-level encryption key overrides make sense, and if so implement them."""

content = content.replace(old_plan, new_plan2)

# Also update TOC: "- [Plan](#plan)" -> "- [TODO](#todo)"
content = content.replace("- [Plan](#plan)", "- [TODO](#todo)")

with open("adrs/modules/20260323-compute-vm-refactoring.md", "w") as f:
    f.write(content)

