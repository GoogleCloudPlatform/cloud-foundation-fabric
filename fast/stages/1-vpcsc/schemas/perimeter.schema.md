# perimeters

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- **description**: *string*
- **title**: *string*
- **spec**: *object*
  <br>*no additional properties allowed*
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
  <br>*no additional properties allowed*
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
- **use_explicit_dry_run_spec**: *boolean*

## Definitions

- **VpcAccessibleServices**<a name="refs-VpcAccessibleServices"></a>: *object*
  <br>*no additional properties allowed*
  - ⁺**allowed_services**: *array*
    - items: *string*
  - **enable_restriction**: *boolean*