
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [billing_account_id](variables.tf#L27) | Billing account id. | <code>string</code> | ✓ |  |
| [folder_id](variables.tf#L95) | Folder ID for the folder where the project will be created. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L183) | Project id. | <code>string</code> | ✓ |  |
| [artifact_registry](variables.tf#L17) | Artifact Refistry repositories for the project. | <code title="map&#40;object&#40;&#123;&#10;  format &#61; string&#10;  region &#61; string&#10;  &#125;&#10;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#41;&#41;</code> |  | <code>null</code> |
| [billing_alert](variables.tf#L32) | Billing alert configuration. | <code title="object&#40;&#123;&#10;  amount &#61; number&#10;  thresholds &#61; object&#40;&#123;&#10;    current    &#61; list&#40;number&#41;&#10;    forecasted &#61; list&#40;number&#41;&#10;  &#125;&#41;&#10;  credit_treatment &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [buckets](variables.tf#L45) | Create GCS Buckets. | <code title="map&#40;object&#40;&#123;&#10;  region &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [datasets](variables.tf#L53) | Create BigQuery Datasets. | <code title="map&#40;object&#40;&#123;&#10;  region &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [defaults](variables.tf#L61) | Project factory default values. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  billing_alert &#61; object&#40;&#123;&#10;    amount &#61; number&#10;    thresholds &#61; object&#40;&#123;&#10;      current    &#61; list&#40;number&#41;&#10;      forecasted &#61; list&#40;number&#41;&#10;    &#125;&#41;&#10;    credit_treatment &#61; string&#10;  &#125;&#41;&#10;  environment_dns_zone  &#61; string&#10;  essential_contacts    &#61; list&#40;string&#41;&#10;  labels                &#61; map&#40;string&#41;&#10;  notification_channels &#61; list&#40;string&#41;&#10;  shared_vpc_self_link  &#61; string&#10;  vpc_host_project      &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [dns_zones](variables.tf#L83) | DNS private zones to create as child of var.defaults.environment_dns_zone. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [essential_contacts](variables.tf#L89) | Email contacts to be used for billing and GCP notifications. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [group_iam](variables.tf#L100) | Custom IAM settings in group => [role] format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L106) | Custom IAM settings in role => [principal] format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [kms_service_agents](variables.tf#L112) | KMS IAM configuration in as service => [key]. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L118) | Labels to be assigned at project level. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [notebooks](variables.tf#L124) | Vertex AI workbenchs to be deployed. | <code title="map&#40;object&#40;&#123;&#10;  owner                 &#61; string&#10;  region                &#61; string&#10;  subnet                &#61; string&#10;  internal_ip_only      &#61; bool&#10;  idle_shutdown_timeout &#61; bool&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [org_policies](variables.tf#L137) | Org-policy overrides at project level. | <code title="map&#40;object&#40;&#123;&#10;  inherit_from_parent &#61; optional&#40;bool&#41; &#35; for list policies only.&#10;  reset               &#61; optional&#40;bool&#41;&#10;  allow &#61; optional&#40;object&#40;&#123;&#10;    all    &#61; optional&#40;bool&#41;&#10;    values &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  deny &#61; optional&#40;object&#40;&#123;&#10;    all    &#61; optional&#40;bool&#41;&#10;    values &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  enforce &#61; optional&#40;bool, true&#41; &#35; for boolean policies only.&#10;  rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;    allow &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    deny &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    enforce &#61; optional&#40;bool, true&#41; &#35; for boolean policies only.&#10;    condition &#61; object&#40;&#123;&#10;      description &#61; optional&#40;string&#41;&#10;      expression  &#61; optional&#40;string&#41;&#10;      location    &#61; optional&#40;string&#41;&#10;      title       &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L177) | Prefix used for the project id. | <code>string</code> |  | <code>null</code> |
| [repo_name](variables.tf#L188) | Cloud Source Repository name. null to avoid to create it. | <code>string</code> |  | <code>null</code> |
| [secrets](variables.tf#L194) | Secrets to be created, and roles to assign them. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [secrets_iam](variables.tf#L200) | IAM bindings on secrets resources. Format is KEY => {ROLE => [MEMBERS]}. | <code>map&#40;map&#40;list&#40;string&#41;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_accounts](variables.tf#L207) | Service accounts to be created, and roles to assign them. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_accounts_iam](variables.tf#L213) | IAM bindings on service account resources. Format is KEY => {ROLE => [MEMBERS]}. | <code>map&#40;map&#40;list&#40;string&#41;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_identities_iam](variables.tf#L220) | Custom IAM settings for service identities in service => [role] format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [services](variables.tf#L227) | Services to be enabled for the project. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [vpc](variables.tf#L234) | Shared VPC configuration for the project. | <code title="object&#40;&#123;&#10;  host_project &#61; string&#10;  gke_setup &#61; object&#40;&#123;&#10;    enable_security_admin     &#61; bool&#10;    enable_host_service_agent &#61; bool&#10;  &#125;&#41;&#10;  subnets_iam &#61; map&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [vpc_local](variables.tf#L247) | Local VPC configuration for the project. | <code title="object&#40;&#123;&#10;  name              &#61; string&#10;  psa_config_ranges &#61; map&#40;string&#41;&#10;  subnets &#61; list&#40;object&#40;&#123;&#10;    name               &#61; string&#10;    region             &#61; string&#10;    ip_cidr_range      &#61; string&#10;    secondary_ip_range &#61; map&#40;string&#41;&#10;    &#125;&#10;  &#41;&#41;&#10;  &#125;&#10;&#41;">object&#40;&#123;&#8230;&#41;</code> |  | <code>null</code> |
| [workload_identity](variables.tf#L264) | Create Workload Identity Pool for Github. | <code title="object&#40;&#123;&#10;  identity_pool_claims &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [github](outputs.tf#L31) | Github Configuration. |  |
| [google_iam_workload_identity_pool_provider](outputs.tf#L37) | Id for the Workload Identity Pool Provider. |  |
| [project](outputs.tf#L42) | The project resource as return by the `project` module. |  |
| [project_id](outputs.tf#L52) | Project ID. |  |
| [workload_identity_pool_name](outputs.tf#L61) | Resource name for the Workload Identity Pool. |  |

<!-- END TFDOC -->
