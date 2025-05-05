# VPC-SC access level

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- **combining_function**: *string*
- **conditions**: *array*
  - items: *object*
    <br>*no additional properties allowed*
    - **device_policy**: *object*
      <br>*no additional properties allowed*
      - **allowed_device_management_levels**: *array*
        - items: *string*
      - **allowed_encryption_statuses**: *array*
        - items: *string*
      - ⁺**require_admin_approval**: *boolean*
      - ⁺**require_corp_owned**: *boolean*
      - **require_screen_lock**: *boolean*
      - **os_constraints**: *array*
        - items: *object*
          <br>*no additional properties allowed*
          - **os_type**: *string*
          - **minimum_version**: *string*
          - **require_verified_chrome_os**: *boolean*
    - **ip_subnetworks**: *array*
      - items: *string*
    - **members**: *array*
      - items: *string*
    - **negate**: *boolean*
    - **regions**: *array*
      - items: *string*
    - **required_access_levels**: *array*
      - items: *string*
    - **vpc_subnets**: *object*
      <br>*no additional properties allowed*
      - **`^//compute.googleapis.com/projects/[^/]+/global/networks/[^/]+$`**: *array*
        - items: *string*

## Definitions

