# VPC-SC access level

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **combining_function**: *string*
  <br>*pattern: None*
- **conditions**: *array*
  - items: *object*
    <br>*additional properties: false*
    - **device_policy**: *object*
      <br>*additional properties: false*
      - **allowed_device_management_levels**: *array*
        - items: *string*
          <br>*pattern: None*
      - **allowed_encryption_statuses**: *array*
        - items: *string*
          <br>*pattern: None*
      - ⁺**require_admin_approval**: *boolean*
      - ⁺**require_corp_owned**: *boolean*
      - **require_screen_lock**: *boolean*
      - **os_constraints**: *array*
        - items: *object*
          <br>*additional properties: false*
          - **os_type**: *string*
            <br>*pattern: None*
          - **minimum_version**: *string*
            <br>*pattern: None*
          - **require_verified_chrome_os**: *boolean*
    - **ip_subnetworks**: *array*
      - items: *string*
        <br>*pattern: None*
    - **members**: *array*
      - items: *string*
        <br>*pattern: None*
    - **negate**: *boolean*
    - **regions**: *array*
      - items: *string*
        <br>*pattern: None*
    - **required_access_levels**: *array*
      - items: *string*
        <br>*pattern: None*
    - **vpc_subnets**: *object*
      <br>*additional properties: false*
      - **`^//compute.googleapis.com/projects/[^/]+/global/networks/[^/]+$`**: *array*
        - items: *string*
          <br>*pattern: None*

## Definitions


