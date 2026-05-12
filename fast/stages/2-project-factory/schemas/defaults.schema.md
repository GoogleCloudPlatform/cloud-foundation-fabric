# Bootstrap Defaults

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **global**: *object*
  <br>*additional properties: false*
  - ⁺**billing_account**: *string*
  - ⁺**organization**: *object*
    <br>*additional properties: false*
    - **customer_id**: *string*
    - **domain**: *string*
    - ⁺**id**: *integer*
- **observability**: *object*
  <br>*additional properties: false*
  - ⁺**project_id**: *string*
  - ⁺**number**: *string*
- **projects**: *object*
  <br>*additional properties: false*
  - **defaults**: *object*
    <br>*additional properties: false*
    - **billing_account**: *string*
    - **bucket**: *object*
      <br>*additional properties: false*
      - **force_destroy**: *boolean*
    - **contacts**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **deletion_policy**: *string*
      <br>*enum: ['PREVENT', 'DELETE', 'ABANDON']*
    - **labels**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *string*
    - **locations**: *object*
      <br>*additional properties: false*
      - **bigquery**: *string*
      - **logging**: *string*
      - **storage**: *string*
    - **metric_scopes**: *array*
      - items: *string*
    - **parent**: *string*
    - **prefix**: *string*
    - **project_reuse**: *object*
      <br>*additional properties: false*
      - **use_data_source**: *boolean*
      - **attributes**: *object*
        <br>*additional properties: false*
        - ⁺**name**: *string*
        - ⁺**number**: *number*
        - **services_enabled**: *array*
          - items: *string*
    - **service_encryption_key_ids**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **services**: *array*
      - items: *string*
    - **shared_vpc_service_config**: *object*
      <br>*additional properties: false*
      - ⁺**host_project**: *string*
      - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
      - **network_users**: *array*
        - items: *string*
      - **service_agent_iam**: *object*
        <br>*additional properties: array*
      - **service_agent_subnet_iam**: *object*
        <br>*additional properties: array*
      - **service_iam_grants**: *array*
        - items: *string*
      - **network_subnet_users**: *object*
        <br>*additional properties: array*
    - **tag_bindings**: *object*
      <br>*additional properties: string*
    - **service_accounts**: *object*
      <br>*additional properties: object*
    - **universe**: *object*
      <br>*additional properties: false*
      - ⁺**domain**: *string*
      - **forced_jit_service_identities**: *array*
        - items: *string*
      - ⁺**prefix**: *string*
      - **unavailable_service_identities**: *array*
        - items: *string*
    - **vpc_sc**: *object*
      - ⁺**perimeter_name**: *string*
      - **is_dry_run**: *boolean*
  - **overrides**: *object*
    <br>*additional properties: false*
    - **billing_account**: *string*
    - **bucket**: *object*
      <br>*additional properties: false*
      - **force_destroy**: *boolean*
    - **contacts**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **deletion_policy**: *string*
      <br>*enum: ['PREVENT', 'DELETE', 'ABANDON']*
    - **locations**: *object*
      <br>*additional properties: false*
      - **bigquery**: *string*
      - **logging**: *string*
      - **storage**: *string*
    - **parent**: *string*
    - **prefix**: *string*
    - **service_encryption_key_ids**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **tag_bindings**: *object*
      <br>*additional properties: string*
    - **service_accounts**: *object*
      <br>*additional properties: object*
    - **universe**: *object*
      <br>*additional properties: false*
      - ⁺**domain**: *string*
      - **forced_jit_service_identities**: *array*
        - items: *string*
      - ⁺**prefix**: *string*
      - **unavailable_service_identities**: *array*
        - items: *string*
    - **vpc_sc**: *object*
      - ⁺**perimeter_name**: *string*
      - **is_dry_run**: *boolean*
- **vpcs**: *object*
  <br>*additional properties: false*
  - **defaults**: *object*
    <br>*additional properties: false*
    - **project_id**: *string*
    - **description**: *string*
    - **auto_create_subnetworks**: *boolean*
    - **delete_default_routes_on_create**: *boolean*
    - **mtu**: *number*
    - **routing_mode**: *string*
      <br>*enum: ['GLOBAL', 'REGIONAL']*
    - **firewall_policy_enforcement_order**: *string*
      <br>*enum: ['BEFORE_CLASSIC_FIREWALL', 'AFTER_CLASSIC_FIREWALL']*
    - **create_googleapis_routes**: *object*
      <br>*additional properties: false*
      - **directpath**: *boolean*
      - **directpath-6**: *boolean*
      - **private**: *boolean*
      - **private-6**: *boolean*
      - **restricted**: *boolean*
      - **restricted-6**: *boolean*
    - **dns_policy**: *object*
      <br>*additional properties: false*
      - **inbound**: *boolean*
      - **logging**: *boolean*
      - **outbound**: *object*
        <br>*additional properties: false*
        - **private_ns**: *array*
          - items: *string*
        - **public_ns**: *array*
          - items: *string*
    - **ipv6_config**: *object*
      <br>*additional properties: false*
      - **enable_ula_internal**: *boolean*
      - **internal_range**: *string*
  - **overrides**: *object*
    <br>*additional properties: false*
    - **project_id**: *string*
    - **description**: *string*
    - **auto_create_subnetworks**: *boolean*
    - **delete_default_routes_on_create**: *boolean*
    - **mtu**: *number*
    - **routing_mode**: *string*
      <br>*enum: ['GLOBAL', 'REGIONAL']*
    - **firewall_policy_enforcement_order**: *string*
      <br>*enum: ['BEFORE_CLASSIC_FIREWALL', 'AFTER_CLASSIC_FIREWALL']*
    - **create_googleapis_routes**: *object*
      <br>*additional properties: false*
      - **directpath**: *boolean*
      - **directpath-6**: *boolean*
      - **private**: *boolean*
      - **private-6**: *boolean*
      - **restricted**: *boolean*
      - **restricted-6**: *boolean*
    - **dns_policy**: *object*
      <br>*additional properties: false*
      - **inbound**: *boolean*
      - **logging**: *boolean*
      - **outbound**: *object*
        <br>*additional properties: false*
        - **private_ns**: *array*
          - items: *string*
        - **public_ns**: *array*
          - items: *string*
    - **ipv6_config**: *object*
      <br>*additional properties: false*
      - **enable_ula_internal**: *boolean*
      - **internal_range**: *string*
- **context**: *object*
  <br>*additional properties: false*
  - **cidr_ranges_sets**: *object*
    <br>*additional properties: array*
  - **custom_roles**: *object*
    <br>*additional properties: string*
  - **email_addresses**: *object*
    <br>*additional properties: string*
  - **folder_ids**: *object*
    <br>*additional properties: string*
  - **kms_keys**: *object*
    <br>*additional properties: string*
  - **iam_principals**: *object*
    <br>*additional properties: string*
  - **locations**: *object*
    <br>*additional properties: string*
  - **notification_channels**: *object*
    <br>*additional properties: string*
  - **project_ids**: *object*
    <br>*additional properties: string*
  - **service_account_ids**: *object*
    <br>*additional properties: string*
  - **tag_keys**: *object*
    <br>*additional properties: string*
  - **tag_values**: *object*
    <br>*additional properties: string*
  - **tag_vars**: *object*
    <br>*additional properties: false*
    - **projects**: *object*
      <br>*additional properties: object*
    - **organization**: *string*
  - **vpc_host_projects**: *object*
    <br>*additional properties: string*
  - **vpc_sc_perimeters**: *object*
    <br>*additional properties: string*
  - **workload_identity_pools**: *object*
    <br>*additional properties: string*
  - **workload_identity_providers**: *object*
    <br>*additional properties: string*
- **output_files**: *object*
  <br>*additional properties: false*
  - **local_path**: *string*
  - **storage_bucket**: *string*
  - **providers**: *object*
    <br>*additional properties: false*
    - **`^[a-z0-9][a-z0-9_-]+$`**: *object*
      <br>*additional properties: false*
      - ⁺**bucket**: *string*
      - **prefix**: *string*
      - ⁺**service_account**: *string*

## Definitions

- **[iam](#ref-iam_ex)**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:roles/|\$custom_roles:|organizations/[0-9]+/roles/|([a-z0-9.]+:)?projects/[a-z0-9-]+/roles/)`**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:||\$iam_principals:[a-z0-9_-]+)*
- **[iam_bindings](#refs-iam_bindings_ex)**<a name="refs-iam_bindings"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **members**: *array*
      - items: *string*
        <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|\$custom_roles:|organizations/[0-9]+/roles/|([a-z0-9.]+:)?projects/[a-z0-9-]+/roles/)*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **[iam_bindings_additive](#refs-iam_additive_ex)**<a name="refs-iam_bindings_additive"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **member**: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|\$custom_roles:|organizations/[0-9]+/roles/|([a-z0-9.]+:)?projects/[a-z0-9-]+/roles/)*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **[iam_by_principals](#refs-iam_by_principals_ex)**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)`**: *array*
    - items: *string*
      <br>*pattern: ^(?:roles/|\$custom_roles:|organizations/[0-9]+/roles/|([a-z0-9.]+:)?projects/[a-z0-9-]+/roles/)*






## Variables

| name | descriptios  | scope & inpact | example | scenario |
|---|-----|:---:|:---:|:---:|
| billing_account | billing_account: The unique ID for the central billing profile that pays for all resources in this project. | Org Level: Financial backbone. | "012345-6789AB-CDEFGH" |
| customer_id | customer_id: The primary identification number for your Google Workspace or Cloud Identity account. | Org Level: Identity foundation. | "C0123abcd" |
| domain | domain: The verified primary web address (e.g., yourcompany.com) associated with your Cloud Identity. | Org Level: Digital boundary. | "example.com" |
| observability | observability: Defines the centralized project where all logs, metrics, and monitoring dashboards are stored. | Management Level: Operations hub. | {"project_id": "monitoring-prod"} |
| locations | locations: Sets the default physical data center regions for BigQuery, Logging, and Storage buckets. | Region Level: Data residency. | {"storage": "EU", "bigquery": "US"} |
| metric_scopes | metric_scopes: A list of other projects that this project is allowed to "see" and monitor for performance data. | Management Level: Monitoring bridge. | ["project-a", "project-b"] |
| project_reuse | project_reuse: Allows the tool to use an existing GCP project instead of creating a brand new one from scratch. | Safety Level: Resource lifecycle. | {"use_data_source": true} |
| tag_bindings | tag_bindings: Key-value pairs used to apply high-level organization tags (like 'environment=prod') for policy control. | Governance Level: Policy tagging. | {"env": "production"} |
| services | services: A list of Google APIs (like Compute or Storage) that must be activated for the project to function. | Enablement Level: API access. | ["compute.googleapis.com"] |
| mtu | mtu: Sets the maximum size of a data packet on the network; higher values can improve speed for certain workloads. | Network Level: Performance tuning. | 1460 |
| routing_mode | routing_mode: Determines if network traffic is visible globally or restricted only to its local region. | Network Level: Traffic scope. | "GLOBAL" |
| dns_policy | dns_policy: Configures how the network handles web address lookups, including logging and private server access. | Network Level: Name resolution. | {"logging": true, "inbound": true} |
| shared_vpc_service_config | shared_vpc_service_config: Links this project to a central "Host" network project, allowing it to use shared subnets. | Network Level: Infrastructure sharing. | {"host_project": "vpc-host-p1"} |
|iam | iam: Defines authoritative role assignments (meaning it overwrites existing ones) for users, groups, or service accounts at the current resource level. reference(iam). | Project-Wide: High-level security control. <a name="refs-iam_ex"></a>| {"roles/owner": ["user:admin@co.com"]} | A new Director taking over and issuing a brand new access list.|
|iam_bindings  | iam_billing_roles: Assigns IAM roles specifically to manage or view the GCP Billing Account. reference(iam_billing_roles)| {"dev-group": ["roles/viewer"]} reference([iam_bindings](#refs-iam_bindingse)). <a name="refs-iam_bindings_ex"></a> | Giving the "Accounting Team" a keycard for the "Records" room.|
| iam_by_principle | iam_by_principle: Assigns multiple IAM roles to a specific user, group, or service account across the project in a single configuration. | Identity Level: Consolidated permissions for one principal. <a name="refs-iam_by_principals_ex"></a> | {"user:admin@company.com": ["roles/viewer", "roles/editor"]} |
| condition | condition: A "logic gate" that only turns on permissions during certain times or for certain resources. | Security Level: Conditional access. | {"title": "Expiring", "expression": "request.time < ..."} |
| local_path | local_path: The folder on your local computer or server where the generated configuration files will be saved. | System Level: File destination. | "/home/user/configs" |
| storage_bucket | storage_bucket: The name of the Cloud Storage bucket where backup copies of the configuration are stored. | Backup Level: Remote storage. | "terraform-state-prod" |
| iam_bindings_additive | iam_bindings_additive: Safely appends new IAM permissions without deleting or overwriting existing bindings (ideal for shared resources). reference(iam_bindings_additive)| Individual Level: Precise access for one person. | {"consultant": ["roles/editor"]} <a name="refs-iam_additive_ex"></a>| Giving a temporary visitor pass to a specific contractor.|

