# Data Domain

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**name**: *string*
  <br>*pattern: None*
- **short_name**: *string*
  <br>*pattern: None*
- **automation**: *object*
  <br>*additional properties: false*
  - **location**: *string*
    <br>*pattern: None*
  - **impersonation_principals**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
- **deploy_config**: *object*
  <br>*additional properties: false*
  - **composer**: *object*
    <br>*additional properties: false*
    - **encryption_key**: *string*
      <br>*pattern: None*
    - **environment_size**: *string*
      <br>*default: ENVIRONMENT_SIZE_SMALL*, *enum: ['ENVIRONMENT_SIZE_SMALL', 'ENVIRONMENT_SIZE_MEDIUM', 'ENVIRONMENT_SIZE_LARGE']*, *pattern: None*
    - **node_config**: *object*
      <br>*additional properties: false*
      - **service_account**: *string*
        <br>*pattern: None*
      - ⁺**network**: *string*
        <br>*pattern: None*
      - ⁺**subnetwork**: *string*
        <br>*pattern: None*
    - **private_builds**: *boolean*
    - **private_environment**: *boolean*
    - **region**: *string*
      <br>*pattern: None*
    - **workloads_config**: *object*
      <br>*additional properties: false*
      - **dag_processor**: *reference([composer_workload](#refs-composer_workload))*
      - **triggerer**: *reference([composer_workload](#refs-composer_workload))*
      - **scheduler**: *reference([composer_workload](#refs-composer_workload))*
      - **web_server**: *reference([composer_workload](#refs-composer_workload))*
      - **worker**: *object*
        <br>*additional properties: false*
        - **cpu**: *number*
        - **memory_gb**: *number*
        - **storage_gb**: *number*
        - **min_count**: *integer*
        - **max_count**: *integer*
- **folder_config**: *object*
  <br>*additional properties: false*
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **project_config**: *object*
  <br>*additional properties: false*
  - **name**: *string*
    <br>*pattern: None*
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
  - **services**: *array*
    - items: *string*
      <br>*pattern: None*
  - **shared_vpc_service_config**: *object*
    <br>*additional properties: false*
    - ⁺**host_project**: *string*
      <br>*pattern: None*
    - **network_users**: *array*
      - items: *string*
        <br>*pattern: None*
    - **service_agent_iam**: *object*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
          <br>*pattern: None*
    - **service_iam_grants**: *array*
      - items: *string*
        <br>*pattern: None*
- **service_accounts**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - **description**: *string*
      <br>*pattern: None*
    - **iam**: *reference([iam](#refs-iam))*
    - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
    - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
    - **iam_storage_roles**: *reference([iam_storage_roles](#refs-iam_storage_roles))*
    - **name**: *string*
      <br>*pattern: None*

## Definitions

- **composer_workload**<a name="refs-composer_workload"></a>: *object*
  <br>*additional properties: false*
  - **cpu**: *number*
  - **memory_gb**: *number*
  - **storage_gb**: *number*
  - **count**: *integer*
- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:roles/|[a-z_]+)`**: *array*
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
      <br>*pattern: ^(?:roles/|[a-z])*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
        <br>*pattern: None*
      - ⁺**title**: *string*
        <br>*pattern: None*
      - **description**: *string*
        <br>*pattern: None*
- **iam_bindings_additive**<a name="refs-iam_bindings_additive"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **member**: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|[a-z])*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
        <br>*pattern: None*
      - ⁺**title**: *string*
        <br>*pattern: None*
      - **description**: *string*
        <br>*pattern: None*
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z]+[a-z0-9-]+$`**: *array*
    - items: *string*
      <br>*pattern: ^(?:roles/|[a-z_]+)*
- **iam_storage_roles**<a name="refs-iam_storage_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
      <br>*pattern: None*
