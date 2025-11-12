# Terraform Variable to JSON Schema Conversion

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**location**: *string*
- ⁺**project_id**: *string*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- ⁺**ca_pool_config**: *object*
  <br>*additional properties: false*
  - **create_pool**: *object*
    <br>*additional properties: false*
    - **name**: *string*
    - **enterprise_tier**: *boolean*
  - **use_pool**: *object*
    <br>*additional properties: false*
    - ⁺**id**: *string*
- **ca_configs**: *object*
  <br>*additional properties: false*
  - **`^[a-z][a-z0-9-]+`**: *object*
    <br>*additional properties: false*
    - **deletion_protection**: *boolean*
    - **is_ca**: *boolean*
    - **is_self_signed**: *boolean*
    - **lifetime**: *string*
    - **pem_ca_certificate**: *string*
    - **ignore_active_certificates_on_deletion**: *boolean*
    - **skip_grace_period**: *boolean*
    - **labels**: *object*
    - **gcs_bucket**: *string*
    - **key_spec**: *object*
      <br>*additional properties: false*
      - **algorithm**: *string*
        <br>*default: RSA_PKCS1_2048_SHA256*, *enum: ['EC_P256_SHA256', 'EC_P384_SHA384', 'RSA_PSS_2048_SHA256', 'RSA_PSS_3072_SHA256', 'RSA_PSS_4096_SHA256', 'RSA_PKCS1_2048_SHA256', 'RSA_PKCS1_3072_SHA256', 'RSA_PKCS1_4096_SHA256', 'SIGN_HASH_ALGORITHM_UNSPECIFIED']*
      - **kms_key_id**: *string*
    - **key_usage**: *object*
      <br>*additional properties: false*
      - **cert_sign**: *boolean*
      - **client_auth**: *boolean*
      - **code_signing**: *boolean*
      - **content_commitment**: *boolean*
      - **crl_sign**: *boolean*
      - **data_encipherment**: *boolean*
      - **decipher_only**: *boolean*
      - **digital_signature**: *boolean*
      - **email_protection**: *boolean*
      - **encipher_only**: *boolean*
      - **key_agreement**: *boolean*
      - **key_encipherment**: *boolean*
      - **ocsp_signing**: *boolean*
      - **server_auth**: *boolean*
      - **time_stamping**: *boolean*
    - **subject**: *object*
      <br>*additional properties: false*
      - ⁺**common_name**: *string*
      - ⁺**organization**: *string*
      - **country_code**: *string*
      - **locality**: *string*
      - **organizational_unit**: *string*
      - **postal_code**: *string*
      - **province**: *string*
      - **street_address**: *string*
    - **subject_alt_name**: *object*
      <br>*additional properties: false*
      - **dns_names**: *array*
        - items: *string*
      - **email_addresses**: *array*
        - items: *string*
      - **ip_addresses**: *array*
        - items: *string*
      - **uris**: *array*
        - items: *string*
    - **subordinate_config**: *object*
      <br>*additional properties: false*
      - **root_ca_id**: *string*
      - **pem_issuer_certificates**: *array*
        - items: *string*

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
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)`**: *array*
    - items: *string*
      <br>*pattern: ^(?:roles/|\$custom_roles:)*
