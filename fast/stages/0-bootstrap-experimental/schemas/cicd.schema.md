# CI/CD Configuration

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

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
      - ⁺**issuer**: *string*
        <br>*enum: ['github', 'gitlab', 'terraform']*
- **workflows**: *object*
  <br>*additional properties: false*
  - **`^[a-z-][a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - **output_files**: *object*
      <br>*additional properties: false*
      - **files**: *array*
        - items: *string*
      - ⁺**providers**: *object*
        <br>*additional properties: false*
        - ⁺**apply**: *string*
        - ⁺**plan**: *string*
      - ⁺**storage_bucket**: *string*
    - **repository**: *object*
      <br>*additional properties: false*
      - ⁺**name**: *string*
      - **branch**: *string*
    - **service_accounts**: *object*
      <br>*additional properties: false*
      - **apply**: *string*
      - **plan**: *string*
    - **template**: *string*
      <br>*enum: ['github', 'gitlab']*
    - **workload_identity_provider**: *object*
      <br>*additional properties: false*
      - **audiences**: *array*
        - items: *string*
      - ⁺**id**: *string*

## Definitions


