# Data Domain

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**name**: *string*
- **short_name**: *string*
- **automation**: *object*
  <br>*additional properties: false*
  - **location**: *string*
  - **impersonation_principals**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
- **deploy_config**: *object*
  <br>*additional properties: false*
  - **composer**: *object*
    <br>*additional properties: false*
    - **encryption_key**: *string*
    - **environment_size**: *string*
      <br>*default: ENVIRONMENT_SIZE_SMALL*, *enum: ['ENVIRONMENT_SIZE_SMALL', 'ENVIRONMENT_SIZE_MEDIUM', 'ENVIRONMENT_SIZE_LARGE']*
    - **node_config**: *object*
      <br>*additional properties: false*
      - **service_account**: *string*
      - ⁺**network**: *string*
      - ⁺**subnetwork**: *string*
    - **private_builds**: *boolean*
    - **private_environment**: *boolean*
    - **region**: *string*
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
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
  - **services**: *array*
    - items: *string*
  - **shared_vpc_service_config**: *object*
    <br>*additional properties: false*
    - ⁺**host_project**: *string*
    - **network_users**: *array*
      - items: *string*
    - **service_agent_iam**: *object*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **service_iam_grants**: *array*
      - items: *string*
- **service_accounts**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - **description**: *string*
    - **iam**: *reference([iam](#refs-iam))*
    - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
    - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
    - **iam_storage_roles**: *reference([iam_storage_roles](#refs-iam_storage_roles))*
    - **name**: *string*

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
      - ⁺**title**: *string*
      - **description**: *string*
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
      - ⁺**title**: *string*
      - **description**: *string*
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z]+[a-z0-9-]+$`**: *array*
    - items: *string*
      <br>*pattern: ^(?:roles/|[a-z_]+)*
- **iam_storage_roles**<a name="refs-iam_storage_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
