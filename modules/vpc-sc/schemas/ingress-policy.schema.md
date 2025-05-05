# VPC-SC ingress policy

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- **title**: *string*
- ⁺**from**: *object*
  <br>*no additional properties allowed*
  - **access_levels**: *array*
    - items: *string*
  - **identity_type**: *string*
<br>, *enum: ['IDENTITY_TYPE_UNSPECIFIED', 'ANY_IDENTITY', 'ANY_USER_ACCOUNT', 'ANY_SERVICE_ACCOUNT', '']*
  - **identities**: *array*
    - items: *string*
  - **resources**: *array*
    - items: *string*
- ⁺**to**: *object*
  <br>*no additional properties allowed*
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

