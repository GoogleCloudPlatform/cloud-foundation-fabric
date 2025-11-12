# CI/CD Configuration

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **workflows**: *object*
  <br>*additional properties: false*
  - **`^[a-z-][a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**provider_files**: *object*
      <br>*additional properties: false*
      - ⁺**apply**: *string*
      - ⁺**plan**: *string*
    - ⁺**repository**: *object*
      <br>*additional properties: false*
      - ⁺**name**: *string*
      - ⁺**type**: *string*
        <br>*enum: ['github', 'gitlab']*
      - **apply_branches**: *array*
        - items: *string*
    - ⁺**service_accounts**: *object*
      <br>*additional properties: false*
      - ⁺**apply**: *string*
      - ⁺**plan**: *string*
    - **tfvars_files**: *array*
      - items: *string*
    - ⁺**workload_identity**: *object*
      <br>*additional properties: false*
      - ⁺**pool_id**: *string*
      - **audiences**: *array*
        - items: *string*
- **workload_identity_federation**: *object*
  <br>*additional properties: false*
  - ⁺**pool_name**: *string*
  - ⁺**project**: *string*
  - **providers**: *object*
    <br>*additional properties: false*
    - **`^[a-z-][a-z0-9-]+$`**: *object*
      <br>*additional properties: false*
      - **attribute_condition**: *string*
      - **custom_settings**: *object*
        <br>*additional properties: false*
        - **issuer_uri**: *string*
        - **audiences**: *array*
          - items: *string*
        - **jwks_json_path**: *string*
        - **okta**: *object*
          <br>*additional properties: false*
          - **organization_name**: *string*
          - **auth_server_name**: *string*

## Definitions


