# KMS Keyring

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**location**: *string*
- ⁺**project_id**: *string*
- **name**: *string*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **reuse**: *boolean*
- **keys**: *object*
  <br>*additional properties: false*
  - **`^[a-z][a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - **destroy_scheduled_duration**: *string*
    - **rotation_period**: *string*
    - **labels**: *string*
    - **purpose**: *string*
      <br>*default: ENCRYPT_DECRYPT*, *enum: ['CRYPTO_KEY_PURPOSE_UNSPECIFIED', 'ENCRYPT_DECRYPT', 'ASYMMETRIC_SIGN', 'ASYMMETRIC_DECRYPT', 'RAW_ENCRYPT_DECRYPT', 'MAC']*
    - **skip_initial_version_creation**: *boolean*
    - **version_template**: *object*
      <br>*additional properties: false*
      - **algorithm**: *string*
      - **protection_level**: *string*
        <br>*default: SOFTWARE*, *enum: ['SOFTWARE', 'HSM', 'EXTERNAL', 'EXTERNAL_VPC']*
    - **iam**: *reference([iam](#refs-iam))*
    - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
    - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^roles/`**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
- **iam_bindings**<a name="refs-iam_bindings"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **members**: *array*
      - items: *string*
        <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
    - **role**: *string*
      <br>*pattern: ^roles/*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **iam_bindings_additive**<a name="refs-iam_bindings_additive"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **member**: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
    - **role**: *string*
      <br>*pattern: ^[a-zA-Z0-9_/]+$*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
