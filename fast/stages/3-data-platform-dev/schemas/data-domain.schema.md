# Data Domain

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- ⁺**name**: *string*
- **short_name**: *string*
- **automation**: *object*
  <br>*no additional properties allowed*
  - **location**: *string*
  - **impersonation_principals**: *array*
    - items: *string*
- **deploy_config**: *object*
  <br>*no additional properties allowed*
  - **composer**: *object*
    <br>*no additional properties allowed*
    - **encryption_key**: *string*
    - **environment_size**: *string*
<br>*default: ENVIRONMENT_SIZE_SMALL*, *enum: ['ENVIRONMENT_SIZE_SMALL', 'ENVIRONMENT_SIZE_MEDIUM', 'ENVIRONMENT_SIZE_LARGE']*
    - ⁺**node_config**: *object*
      <br>*no additional properties allowed*
      - **service_account**: *string*
      - ⁺**network**: *string*
      - ⁺**subnetwork**: *string*
    - **private_builds**: *boolean*
    - **private_environment**: *boolean*
    - **region**: *string*
    - **workloads_config**: *object*
      <br>*no additional properties allowed*
      - **dag_processor**: *reference([composer_workload](#refs-composer_workload))*
      - **triggerer**: *reference([composer_workload](#refs-composer_workload))*
      - **scheduler**: *reference([composer_workload](#refs-composer_workload))*
      - **web_server**: *reference([composer_workload](#refs-composer_workload))*
      - **worker**: *object*
        <br>*no additional properties allowed*
        - **cpu**: *number*
        - **memory_gb**: *number*
        - **storage_gb**: *number*
        - **min_count**: *number*
        - **max_count**: *number*
- **folder_config**: *object*
  <br>*no additional properties allowed*
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **project_config**: *object*
  <br>*no additional properties allowed*
  - **name**: *string*
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
  - **services**: *array*
    - items: *string*
  - **shared_vpc_service_config**: *object*
    <br>*no additional properties allowed*
    - ⁺**host_project**: *string*
    - **network_users**: *array*
      - items: *string*
    - **service_agent_iam**: *object*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **service_iam_grants**: *array*
      - items: *string*
- **service_accounts**: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*no additional properties allowed*
    - **description**: *string*
    - **iam**: *reference([iam](#refs-iam))*
    - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
    - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
    - **iam_storage_roles**: *reference([iam_storage_roles](#refs-iam_storage_roles))*
    - **name**: *string*

## Definitions

- **composer_workload**<a name="refs-composer_workload"></a>: *object*
  <br>*no additional properties allowed*
  - **cpu**: *number*
  - **memory_gb**: *number*
  - **storage_gb**: *number*
  - **count**: *number*
- **iam**<a name="refs-iam"></a>: *object*
  <br>*no additional properties allowed*
  - **`^(?:roles/|[a-z_]+)`**: *array*
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
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z]+[a-z0-9-]+$`**: *array*
    - items: *string*
- **iam_storage_roles**<a name="refs-iam_storage_roles"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*