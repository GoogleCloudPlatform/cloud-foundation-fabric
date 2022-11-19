
<!-- BEGIN TFDOC -->

## Files

| name | description | modules | resources |
|---|---|---|---|
| [ci-cd.tf](./ci-cd.tf) | None | <code>artifact-registry</code> · <code>iam-service-account</code> | <code>google_iam_workload_identity_pool</code> · <code>google_iam_workload_identity_pool_provider</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>bigquery-dataset</code> · <code>dns</code> · <code>gcs</code> · <code>iam-service-account</code> · <code>net-cloudnat</code> · <code>net-vpc</code> · <code>net-vpc-firewall</code> · <code>project</code> | <code>google_compute_subnetwork_iam_member</code> · <code>google_sourcerepo_repository</code> |
| [notebooks.tf](./notebooks.tf) | None |  | <code>google_notebooks_runtime</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [billing_account_id](variables.tf#L28) | Billing account id. | <code>string</code> | ✓ |  |
| [folder_id](variables.tf#L96) | Folder ID for the folder where the project will be created. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L158) | Project id. | <code>string</code> | ✓ |  |
| [artifact_registry](variables.tf#L17) | Artifact Refistry repositories for the project. | <code title="map&#40;object&#40;&#123;&#10;  format &#61; string&#10;  region &#61; string&#10;  &#125;&#10;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#41;&#41;</code> |  | <code>null</code> |
| [billing_alert](variables.tf#L33) | Billing alert configuration. | <code title="object&#40;&#123;&#10;  amount &#61; number&#10;  thresholds &#61; object&#40;&#123;&#10;    current    &#61; list&#40;number&#41;&#10;    forecasted &#61; list&#40;number&#41;&#10;  &#125;&#41;&#10;  credit_treatment &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [buckets](variables.tf#L68) | Create GCS Buckets | <code title="map&#40;object&#40;&#123;&#10;  region &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [datasets](variables.tf#L76) | Create BigQuery Datasets | <code title="map&#40;object&#40;&#123;&#10;  region &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [defaults](variables.tf#L46) | Project factory default values. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  billing_alert &#61; object&#40;&#123;&#10;    amount &#61; number&#10;    thresholds &#61; object&#40;&#123;&#10;      current    &#61; list&#40;number&#41;&#10;      forecasted &#61; list&#40;number&#41;&#10;    &#125;&#41;&#10;    credit_treatment &#61; string&#10;  &#125;&#41;&#10;  environment_dns_zone  &#61; string&#10;  essential_contacts    &#61; list&#40;string&#41;&#10;  labels                &#61; map&#40;string&#41;&#10;  notification_channels &#61; list&#40;string&#41;&#10;  shared_vpc_self_link  &#61; string&#10;  vpc_host_project      &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [dns_zones](variables.tf#L84) | DNS private zones to create as child of var.defaults.environment_dns_zone. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [essential_contacts](variables.tf#L90) | Email contacts to be used for billing and GCP notifications. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [group_iam](variables.tf#L101) | Custom IAM settings in group => [role] format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L107) | Custom IAM settings in role => [principal] format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [kms_service_agents](variables.tf#L113) | KMS IAM configuration in as service => [key]. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L119) | Labels to be assigned at project level. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [notebooks](variables.tf#L125) | Vertex AI workbenchs to be deployed | <code title="map&#40;object&#40;&#123;&#10;  owner                 &#61; string&#10;  region                &#61; string&#10;  subnet                &#61; string&#10;  internal_ip_only      &#61; bool&#10;  idle_shutdown_timeout &#61; bool&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [org_policies](variables.tf#L138) | Org-policy overrides at project level. | <code title="object&#40;&#123;&#10;  policy_boolean &#61; map&#40;bool&#41;&#10;  policy_list &#61; map&#40;object&#40;&#123;&#10;    inherit_from_parent &#61; bool&#10;    suggested_value     &#61; string&#10;    status              &#61; bool&#10;    values              &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [prefix](variables.tf#L152) | Prefix used for the project id. | <code>string</code> |  | <code>null</code> |
| [repo_name](variables.tf#L163) | Cloud Source Repository name. null to avoid to create it. | <code>string</code> |  | <code>null</code> |
| [service_accounts](variables.tf#L170) | Service accounts to be created, and roles to assign them. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_identities_iam](variables.tf#L183) | Custom IAM settings for service identities in service => [role] format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [services](variables.tf#L176) | Services to be enabled for the project. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [vpc](variables.tf#L190) | Shared VPC configuration for the project. | <code title="object&#40;&#123;&#10;  host_project &#61; string&#10;  gke_setup &#61; object&#40;&#123;&#10;    enable_security_admin     &#61; bool&#10;    enable_host_service_agent &#61; bool&#10;  &#125;&#41;&#10;  subnets_iam &#61; map&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [vpc_local](variables.tf#L203) | Local VPC configuration for the project. | <code title="object&#40;&#123;&#10;  name              &#61; string&#10;  psa_config_ranges &#61; map&#40;string&#41;&#10;  subnets &#61; list&#40;object&#40;&#123;&#10;    name               &#61; string&#10;    region             &#61; string&#10;    ip_cidr_range      &#61; string&#10;    secondary_ip_range &#61; map&#40;string&#41;&#10;    &#125;&#10;  &#41;&#41;&#10;  &#125;&#10;&#41;">object&#40;&#123;&#8230;&#41;</code> |  | <code>null</code> |
| [workload_identity](variables.tf#L220) | Create Workload Identity Pool for Github | <code title="object&#40;&#123;&#10;  identity_pool_claims &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [google_iam_workload_identity_pool_provider](outputs.tf#L25) | Id for the Workload Identity Pool Provider. |  |
| [project](outputs.tf#L30) | The project resource as return by the `project` module |  |
| [project_id](outputs.tf#L40) | Project ID. |  |
| [workload_identity_pool_name](outputs.tf#L20) | Resource name for the Workload Identity Pool. |  |

<!-- END TFDOC -->
