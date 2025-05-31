# perimeters

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **description**: *string*
- **ignore_resource_changes**: *boolean*
- **spec**: *object*
  <br>*additional properties: false*
  - **access_levels**: *array*
    - items: *string*
  - **egress_policies**: *array*
    - items: *string*
  - **ingress_policies**: *array*
    - items: *string*
  - **restricted_services**: *array*
    - items: *string*
  - **resources**: *array*
    - items: *string*
  - **vpc_accessible_services**: *reference([VpcAccessibleServices](#refs-VpcAccessibleServices))*
- **status**: *object*
  <br>*additional properties: false*
  - **access_levels**: *array*
    - items: *string*
  - **egress_policies**: *array*
    - items: *string*
  - **ingress_policies**: *array*
    - items: *string*
  - **resources**: *array*
    - items: *string*
  - **restricted_services**: *array*
    - items: *string*
  - **vpc_accessible_services**: *reference([VpcAccessibleServices](#refs-VpcAccessibleServices))*
- **title**: *string*
- **use_explicit_dry_run_spec**: *boolean*

## Definitions

- **VpcAccessibleServices**<a name="refs-VpcAccessibleServices"></a>: *object*
  <br>*additional properties: false*
  - ⁺**allowed_services**: *array*
    - items: *string*
  - **enable_restriction**: *boolean*
