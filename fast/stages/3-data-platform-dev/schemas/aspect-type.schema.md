# Dataplex Aspect Type

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- **description**: *string*
- **display_name**: *string*
- **labels**: *object*
- **metadata_template**: *string*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*no additional properties allowed*
  - **`^roles/`**: *array*
    - items: *string*
- **iam_bindings**<a name="refs-iam_bindings"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*no additional properties allowed*
    - **members**: *array*
      - items: *string*
    - **role**: *string*
    - **condition**: *object*
      <br>*no additional properties allowed*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **iam_bindings_additive**<a name="refs-iam_bindings_additive"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*no additional properties allowed*
    - **member**: *string*
    - **role**: *string*
    - **condition**: *object*
      <br>*no additional properties allowed*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*