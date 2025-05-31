# perimeters

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **description**: *string*
  <br>*pattern: None*
- **ignore_resource_changes**: *boolean*
- **spec**: *object*
  <br>*additional properties: false*
  - **access_levels**: *array*
    - items: *string*
      <br>*pattern: None*
  - **egress_policies**: *array*
    - items: *string*
      <br>*pattern: None*
  - **ingress_policies**: *array*
    - items: *string*
      <br>*pattern: None*
  - **restricted_services**: *array*
    - items: *string*
      <br>*pattern: None*
  - **resources**: *array*
    - items: *string*
      <br>*pattern: None*
  - **vpc_accessible_services**: *reference([VpcAccessibleServices](#refs-VpcAccessibleServices))*
- **status**: *object*
  <br>*additional properties: false*
  - **access_levels**: *array*
    - items: *string*
      <br>*pattern: None*
  - **egress_policies**: *array*
    - items: *string*
      <br>*pattern: None*
  - **ingress_policies**: *array*
    - items: *string*
      <br>*pattern: None*
  - **resources**: *array*
    - items: *string*
      <br>*pattern: None*
  - **restricted_services**: *array*
    - items: *string*
      <br>*pattern: None*
  - **vpc_accessible_services**: *reference([VpcAccessibleServices](#refs-VpcAccessibleServices))*
- **title**: *string*
  <br>*pattern: None*
- **use_explicit_dry_run_spec**: *boolean*

## Definitions

- **VpcAccessibleServices**<a name="refs-VpcAccessibleServices"></a>: *object*
  <br>*additional properties: false*
  - ⁺**allowed_services**: *array*
    - items: *string*
      <br>*pattern: None*
  - **enable_restriction**: *boolean*
