# VPC-SC ingress policy

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **title**: *string*
- ⁺**from**: *object*
  <br>*additional properties: false*
  - **access_levels**: *array*
    - items: *string*
  - **identity_type**: *string*
    <br>*enum: ['IDENTITY_TYPE_UNSPECIFIED', 'ANY_IDENTITY', 'ANY_USER_ACCOUNT', 'ANY_SERVICE_ACCOUNT', '']*
  - **identities**: *array*
    - items: *string*
  - **resources**: *array*
    - items: *string*
- ⁺**to**: *object*
  <br>*additional properties: false*
  - **operations**: *array*
    - items: *object*
      - **method_selectors**: *array*
        - items: *string*
      - **permission_selectors**: *array*
        - items: *string*
  - **resources**: *array*
    - items: *string*
  - **roles**: *array*
    - items: *string*

## Definitions


