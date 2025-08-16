# VPC-SC egress policy

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
      <br>*pattern: ^(?:serviceAccount:|user:|group:|principal:|\$identity_sets:)*
  - **resources**: *array*
    - items: *string*
- ⁺**to**: *object*
  <br>*additional properties: false*
  - **external_resources**: *array*
    - items: *string*
  - **operations**: *array*
    - items: *object*
      <br>*additional properties: false*
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


