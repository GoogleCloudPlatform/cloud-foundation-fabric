# VPC-SC ingress policy

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **title**: *string*
  <br>*pattern: None*
- ⁺**from**: *object*
  <br>*additional properties: false*
  - **access_levels**: *array*
    - items: *string*
      <br>*pattern: None*
  - **identity_type**: *string*
    <br>*enum: ['IDENTITY_TYPE_UNSPECIFIED', 'ANY_IDENTITY', 'ANY_USER_ACCOUNT', 'ANY_SERVICE_ACCOUNT', '']*, *pattern: None*
  - **identities**: *array*
    - items: *string*
      <br>*pattern: None*
  - **resources**: *array*
    - items: *string*
      <br>*pattern: None*
- ⁺**to**: *object*
  <br>*additional properties: false*
  - **operations**: *array*
    - items: *object*
      - **method_selectors**: *array*
        - items: *string*
          <br>*pattern: None*
      - **permission_selectors**: *array*
        - items: *string*
          <br>*pattern: None*
  - **resources**: *array*
    - items: *string*
      <br>*pattern: None*
  - **roles**: *array*
    - items: *string*
      <br>*pattern: None*

## Definitions


