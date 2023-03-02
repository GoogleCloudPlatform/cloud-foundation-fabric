# Data Platform

# TODO
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [organization_domain](variables.tf#L155) | Organization domain. | <code>string</code> | ✓ |  |
| [prefix](variables.tf#L160) | Prefix used for resource names. | <code>string</code> | ✓ |  |
| [project_config](variables.tf#L169) | Provide 'billing_account_id' value if project creation is needed, uses existing 'project_ids' if null. Parent is in 'folders/nnn' or 'organizations/nnn' format. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; optional&#40;string, null&#41;&#10;  parent             &#61; string&#10;  project_ids &#61; optional&#40;object&#40;&#123;&#10;    landing    &#61; string&#10;    processing &#61; string&#10;    curated    &#61; string&#10;    common     &#61; string&#10;    &#125;&#41;, &#123;&#10;    landing    &#61; &#34;lnd&#34;&#10;    processing &#61; &#34;prc&#34;&#10;    curated    &#61; &#34;cur&#34;&#10;    common     &#61; &#34;cmn&#34;&#10;    &#125;&#10;  &#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [composer_config](variables.tf#L17) | Cloud Composer config. | <code title="object&#40;&#123;&#10;  disable_deployment &#61; optional&#40;bool&#41;&#10;  environment_size   &#61; optional&#40;string, &#34;ENVIRONMENT_SIZE_SMALL&#34;&#41;&#10;  software_config &#61; optional&#40;object&#40;&#123;&#10;    airflow_config_overrides &#61; optional&#40;any&#41;&#10;    pypi_packages            &#61; optional&#40;any&#41;&#10;    env_variables            &#61; optional&#40;map&#40;string&#41;&#41;&#10;    image_version            &#61; string&#10;    &#125;&#41;, &#123;&#10;    image_version &#61; &#34;composer-2-airflow-2&#34;&#10;  &#125;&#41;&#10;  workloads_config &#61; optional&#40;object&#40;&#123;&#10;    scheduler &#61; optional&#40;object&#40;&#10;      &#123;&#10;        cpu        &#61; number&#10;        memory_gb  &#61; number&#10;        storage_gb &#61; number&#10;        count      &#61; number&#10;      &#125;&#10;      &#41;, &#123;&#10;      cpu        &#61; 0.5&#10;      memory_gb  &#61; 1.875&#10;      storage_gb &#61; 1&#10;      count      &#61; 1&#10;    &#125;&#41;&#10;    web_server &#61; optional&#40;object&#40;&#10;      &#123;&#10;        cpu        &#61; number&#10;        memory_gb  &#61; number&#10;        storage_gb &#61; number&#10;      &#125;&#10;      &#41;, &#123;&#10;      cpu        &#61; 0.5&#10;      memory_gb  &#61; 1.875&#10;      storage_gb &#61; 1&#10;    &#125;&#41;&#10;    worker &#61; optional&#40;object&#40;&#10;      &#123;&#10;        cpu        &#61; number&#10;        memory_gb  &#61; number&#10;        storage_gb &#61; number&#10;        min_count  &#61; number&#10;        max_count  &#61; number&#10;      &#125;&#10;      &#41;, &#123;&#10;      cpu        &#61; 0.5&#10;      memory_gb  &#61; 1.875&#10;      storage_gb &#61; 1&#10;      min_count  &#61; 1&#10;      max_count  &#61; 3&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  environment_size &#61; &#34;ENVIRONMENT_SIZE_SMALL&#34;&#10;  software_config &#61; &#123;&#10;    image_version &#61; &#34;composer-2-airflow-2&#34;&#10;  &#125;&#10;  workloads_config &#61; &#123;&#10;    scheduler &#61; &#123;&#10;      cpu        &#61; 0.5&#10;      memory_gb  &#61; 1.875&#10;      storage_gb &#61; 1&#10;      count      &#61; 1&#10;    &#125;&#10;    web_server &#61; &#123;&#10;      cpu        &#61; 0.5&#10;      memory_gb  &#61; 1.875&#10;      storage_gb &#61; 1&#10;    &#125;&#10;    worker &#61; &#123;&#10;      cpu        &#61; 0.5&#10;      memory_gb  &#61; 1.875&#10;      storage_gb &#61; 1&#10;      min_count  &#61; 1&#10;      max_count  &#61; 3&#10;    &#125;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [data_catalog_tags](variables.tf#L100) | List of Data Catalog Policy tags to be created with optional IAM binging configuration in {tag => {ROLE => [MEMBERS]}} format. | <code>map&#40;map&#40;list&#40;string&#41;&#41;&#41;</code> |  | <code title="&#123;&#10;  &#34;3_Confidential&#34; &#61; null&#10;  &#34;2_Private&#34;      &#61; null&#10;  &#34;1_Sensitive&#34;    &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [data_force_destroy](variables.tf#L111) | Flag to set 'force_destroy' on data services like BiguQery or Cloud Storage. | <code>bool</code> |  | <code>false</code> |
| [groups](variables.tf#L117) | User groups. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  data-analysts  &#61; &#34;gcp-data-analysts&#34;&#10;  data-engineers &#61; &#34;gcp-data-engineers&#34;&#10;  data-security  &#61; &#34;gcp-data-security&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [location](variables.tf#L127) | Location used for multi-regional resources. | <code>string</code> |  | <code>&#34;eu&#34;</code> |
| [network_config](variables.tf#L133) | Shared VPC network configurations to use. If null networks will be created in projects with preconfigured values. | <code title="object&#40;&#123;&#10;  host_project      &#61; string&#10;  network_self_link &#61; string&#10;  subnet_self_links &#61; object&#40;&#123;&#10;    processing_dataproc &#61; string&#10;    processing_composer &#61; string&#10;  &#125;&#41;&#10;  composer_ip_ranges &#61; object&#40;&#123;&#10;    cloudsql   &#61; string&#10;    gke_master &#61; string&#10;  &#125;&#41;&#10;  composer_secondary_ranges &#61; object&#40;&#123;&#10;    pods     &#61; string&#10;    services &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [project_services](variables.tf#L193) | List of core services enabled on all projects. | <code>list&#40;string&#41;</code> |  | <code title="&#91;&#10;  &#34;cloudresourcemanager.googleapis.com&#34;,&#10;  &#34;iam.googleapis.com&#34;,&#10;  &#34;serviceusage.googleapis.com&#34;,&#10;  &#34;stackdriver.googleapis.com&#34;&#10;&#93;">&#91;&#8230;&#93;</code> |
| [project_suffix](variables.tf#L204) | Suffix used only for project ids. | <code>string</code> |  | <code>null</code> |
| [region](variables.tf#L210) | Region used for regional resources. | <code>string</code> |  | <code>&#34;europe-west1&#34;</code> |
| [service_encryption_keys](variables.tf#L216) | Cloud KMS to use to encrypt different services. Key location should match service region. | <code title="object&#40;&#123;&#10;  bq       &#61; string&#10;  composer &#61; string&#10;  compute  &#61; string&#10;  storage  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [bigquery-datasets](outputs.tf#L16) | BigQuery datasets. |  |
| [dataproc-hystory-server](outputs.tf#L78) | Dataproc hystory server |  |
| [dataproc_cluster](outputs.tf#L99) | List of bucket names which have been assigned to the cluster. |  |
| [demo_commands](outputs.tf#L23) | Demo commands. Relevant only if Composer is deployed. |  |
| [gcs-buckets](outputs.tf#L45) | GCS buckets. | ✓ |
| [kms_keys](outputs.tf#L55) | Cloud MKS keys. |  |
| [projects](outputs.tf#L60) | GCP Projects informations. |  |
| [vpc_network](outputs.tf#L83) | VPC network. |  |
| [vpc_subnet](outputs.tf#L91) | VPC subnetworks. |  |

<!-- END TFDOC -->
