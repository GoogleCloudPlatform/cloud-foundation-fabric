# VPC-SC egress policy

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
  - **external_resources**: *array*
    - items: *string*
  - **operations**: *array*
    - items: *object*
      <br>*no additional properties allowed*
      - **method_selectors**: *array*
        - items: *string*
      - **permission_selectors**: *array*
        - items: *string*
      - ⁺**service_name**: *string*
  - **resources**: *array*
    - items: *string*
  - **roles**: *array*
    - items: *string*

## Definitions

