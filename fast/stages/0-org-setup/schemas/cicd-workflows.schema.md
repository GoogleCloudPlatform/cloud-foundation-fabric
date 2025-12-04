# CI/CD Configuration

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

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
    - ⁺**provider**: *string*
    - ⁺**iam_principalsets**: *object*

## Definitions


