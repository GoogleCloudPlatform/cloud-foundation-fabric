# FAST Light Bootstrap

<!-- BEGIN TOC -->
- [Leveraging Classic FAST Stages](#leveraging-classic-fast-stages)
- [VPC Service Controls](#vpc-service-controls)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Leveraging Classic FAST Stages

## VPC Service Controls

```yaml
from:
  access_levels:
    - "*"
  identities:
    - $identity_sets:logging_identities
to:
  operations:
    - service_name: "*"
  resources:
    - $project_numbers:log-0
```

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [billing.tf](./billing.tf) | None | <code>billing-account</code> |  |
| [cicd.tf](./cicd.tf) | None |  | <code>google_iam_workload_identity_pool</code> · <code>google_iam_workload_identity_pool_provider</code> · <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [factory.tf](./factory.tf) | None | <code>project-factory-experimental</code> |  |
| [main.tf](./main.tf) | Module-level locals and resources. |  | <code>terraform_data</code> |
| [organization.tf](./organization.tf) | None | <code>organization</code> |  |
| [output-files.tf](./output-files.tf) | None |  | <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |
| [wif-definitions.tf](./wif-definitions.tf) | Workload Identity provider definitions. |  |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [bootstrap_user](variables.tf#L17) | Email of the nominal user running this stage for the first time. | <code>string</code> |  | <code>null</code> |
| [context](variables.tf#L23) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  custom_roles          &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  folder_ids            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations             &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  kms_keys              &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  notification_channels &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_account_ids   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_values            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  vpc_host_projects     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  vpc_sc_perimeters     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [factories_config](variables.tf#L42) | Configuration for the resource factories or external data. | <code title="object&#40;&#123;&#10;  billing_accounts &#61; optional&#40;string, &#34;data&#47;billing-accounts&#34;&#41;&#10;  cicd             &#61; optional&#40;string, &#34;data&#47;cicd.yaml&#34;&#41;&#10;  defaults         &#61; optional&#40;string, &#34;data&#47;defaults.yaml&#34;&#41;&#10;  folders          &#61; optional&#40;string, &#34;data&#47;folders&#34;&#41;&#10;  organization     &#61; optional&#40;string, &#34;data&#47;organization&#34;&#41;&#10;  projects         &#61; optional&#40;string, &#34;data&#47;projects&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [projects](outputs.tf#L17) |  |  |
<!-- END TFDOC -->
