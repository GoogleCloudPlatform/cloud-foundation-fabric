# Workstation Config

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **annotations**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *string*
- **container**: *object*
  <br>*additional properties: false*
  - **args**: *array*
    - items: *string*
  - **command**: *array*
    - items: *string*
  - **env**: *object*
    <br>*additional properties: string*
  - **image**: *string*
  - **run_as_user**: *string*
  - **working_dir**: *string*
- **display_name**: *string*
- **enable_audit_agent**: *boolean*
- **encryption_key**: *object*
  <br>*additional properties: false*
  - ⁺**kms_key**: *string*
  - ⁺**kms_key_service_account**: *string*
- **gce_instance**: *object*
  <br>*additional properties: false*
  - **machine_type**: *string*
  - **service_account**: *string*
  - **service_account_scopes**: *array*
    - items: *string*
  - **pool_size**: *number*
  - **boot_disk_size_gb**: *number*
  - **tags**: *array*
    - items: *string*
  - **disable_public_ip_addresses**: *boolean*
  - **enable_nested_virtualization**: *boolean*
  - **shielded_instance_config**: *object*
    <br>*additional properties: false*
    - **enable_secure_boot**: *boolean*
    - **enable_vtpm**: *boolean*
    - **enable_integrity_monitoring**: *boolean*
  - **enable_confidential_compute**: *boolean*
  - **accelerators**: *array*
    - items: *object*
      <br>*additional properties: false*
      - **type**: *string*
      - **count**: *number*
- **iam**: *object*
  <br>*additional properties: array*
- **iam_bindings**: *object*
  <br>*additional properties: object*
- **iam_bindings_additive**: *object*
  <br>*additional properties: object*
- **labels**: *object*
  <br>*additional properties: string*
- **max_workstations**: *number*
- **persistent_directories**: *array*
  - items: *object*
    <br>*additional properties: false*
    - **mount_path**: *string*
    - **gce_pd**: *object*
      <br>*additional properties: false*
      - **size_gb**: *number*
      - **fs_type**: *string*
      - **disk_type**: *string*
      - **source_snapshot**: *string*
      - **reclaim_policy**: *string*
- **replica_zones**: *array*
  - items: *string*
- **timeouts**: *object*
  <br>*additional properties: false*
  - **idle**: *number*
  - **running**: *number*
- **workstations**: *object*
  <br>*additional properties: object*

## Definitions


