# Shielded folder

This blueprint implements an opinionated Folder configuration to implement GCP best practices. Configurations implemented on the folder would be beneficial to host Workloads hineriting contrains from the folder they belong to.

In this blueprint, a folder will be created implementing the following features:
- Organizational policies
- Hirarckical firewall rules
- Cloud KMS
- VPC-SC

Within the folder the following projects will be created:
- 'audit-logs' where Audit Logs sink will be created
- 'sec-core' where Cloud KMS and Cloud Secret manager will be configured


The following diagram is a high-level reference of the resources created and managed here:

![Shielded architecture overview](./images/overview_diagram.png "Shielded architecture overview")

# Design overview and choices

Despite its simplicity, this blueprint implements the basics of a design that we've seen working well for various customers.

The approach adapts to different high-level requirements:
- IAM roles inheritance
- Organizational policies
- Audit log sink
- VPC Service Control
- Cloud KMS

# Project structure
The Shielded Folder blueprint is designed to rely on several projects:
- `audit-log`: to host Audit logging buckets and Audit log sync to GCS, BigQuery or PubSub
- `sec-core`: to host security related resources such as Cloud KMS and Cloud Secrets Manager

This separation into projects allows adhering to the least-privilege principle by using project-level roles.

# User groups
User groups provide a stable frame of reference that allows decoupling the final set of permissions from the stage where entities and resources are created, and their IAM bindings defined.

We use three groups to control access to resources:
- `data-engineers`: They handle and run workloads on the `wokload` subfolder. They have owner access to all resources in the `workload` folder in order to troubleshoot possible issues with pipelines. This team can also impersonate any service account.
- `data-security`: They handle security configurations for the shielded folder. They have owner access to the `audit-log` and `sec-core` projects.

# Encryption
The blueprint support the configuration of an instance of Cloud KMS to handle encryption on the resources. The encryption is disabled by default, but you can enble it configuring the `enable_features.kms` variable.

The script will create keys to encrypt log sink bucket/dataset/topic in the specified regions. Configuring the `kms_keys` variable, you can create additional KMS keys needed by your workload.

# How to run this script
To deploy this blueprint on your GCP organization, you will need
- a folder or organization where resources will be created
- a billing account that will be associated with the new projects

The Shielded Folder blueprint is meant to be executed by a Service Account (or a regular user) having this minimal set of permission:
- Billing account
  - `roles/billing.user`
- Folder level
  - `roles/resourcemanager.folderAdmin`
  - `roles/resourcemanager.projectCreator`

The shielded Folfer blueprint assumes [groups described](#groups) are created in your GCP organization.

## Variable configuration
There are three sets of variables you will need to fill in:
```
organization = {
  id     = "12345678"
  domain = "example.com"
}
prefix = "prefix"
```

## Deploying the blueprint
Once the configuration is complete, run the project factory by running

```bash
terraform init
terraform apply
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [organization](variables.tf#L128) | Organization details. | <code title="object&#40;&#123;&#10;  domain &#61; string&#10;  id     &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [prefix](variables.tf#L136) | Prefix used for resources that need unique names. Use 9 characters or less. | <code>string</code> | ✓ |  |
| [access_policy](variables.tf#L17) | Access Policy name, set to null if creating one. | <code>string</code> |  | <code>null</code> |
| [access_policy_create](variables.tf#L23) | Access Policy configuration, fill in to create. Parent is in 'organizations/123456' format. | <code title="object&#40;&#123;&#10;  parent &#61; string&#10;  title  &#61; string&#10;  scopes &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [data_dir](variables.tf#L33) | Relative path for the folder storing configuration data. | <code>string</code> |  | <code>&#34;data&#34;</code> |
| [enable_features](variables.tf#L39) | Flag to enable features on the solution. | <code title="object&#40;&#123;&#10;  kms      &#61; bool&#10;  log_sink &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  kms      &#61; true&#10;  log_sink &#61; true&#10;&#125;">&#123;&#8230;&#125;</code> |
| [folder_create](variables.tf#L50) | Provide values if folder creation is needed, uses existing folder if null. Parent is in 'folders/nnn' or 'organizations/nnn' format. | <code title="object&#40;&#123;&#10;  display_name &#61; string&#10;  parent       &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [folder_id](variables.tf#L59) | Folder ID in case you use folder_create=null. | <code>string</code> |  | <code>null</code> |
| [groups](variables.tf#L65) | User groups. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  data-engineers &#61; &#34;gcp-data-engineers&#34;&#10;  data-security  &#61; &#34;gcp-data-security&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [kms_keys](variables.tf#L75) | KMS keys to create, keyed by name. | <code title="map&#40;object&#40;&#123;&#10;  iam             &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels          &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations       &#61; optional&#40;list&#40;string&#41;, &#91;&#34;global&#34;, &#34;europe&#34;, &#34;europe-west1&#34;&#93;&#41;&#10;  rotation_period &#61; optional&#40;string, &#34;7776000s&#34;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [log_locations](variables.tf#L86) | Optional locations for GCS, BigQuery, and logging buckets created here. | <code title="object&#40;&#123;&#10;  bq      &#61; optional&#40;string, &#34;europe&#34;&#41;&#10;  storage &#61; optional&#40;string, &#34;europe&#34;&#41;&#10;  logging &#61; optional&#40;string, &#34;global&#34;&#41;&#10;  pubsub  &#61; optional&#40;string, &#34;global&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  bq      &#61; &#34;europe&#34;&#10;  storage &#61; &#34;europe&#34;&#10;  logging &#61; &#34;global&#34;&#10;  pubsub  &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [log_sinks](variables.tf#L103) | Org-level log sinks, in name => {type, filter} format. | <code title="map&#40;object&#40;&#123;&#10;  filter &#61; string&#10;  type   &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  audit-logs &#61; &#123;&#10;    filter &#61; &#34;logName:&#92;&#34;&#47;logs&#47;cloudaudit.googleapis.com&#37;2Factivity&#92;&#34; OR logName:&#92;&#34;&#47;logs&#47;cloudaudit.googleapis.com&#37;2Fsystem_event&#92;&#34;&#34;&#10;    type   &#61; &#34;bigquery&#34;&#10;  &#125;&#10;  vpc-sc &#61; &#123;&#10;    filter &#61; &#34;protoPayload.metadata.&#64;type&#61;&#92;&#34;type.googleapis.com&#47;google.cloud.audit.VpcServiceControlAuditMetadata&#92;&#34;&#34;&#10;    type   &#61; &#34;bigquery&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [projects_create](variables.tf#L146) | Provide values if projects creation is needed, uses existing project if null. Projects will be created in the shielded folder. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [projects_id](variables.tf#L154) | Project id, references existing projects if `project_create` is null. Projects will be moved into the shielded folder. | <code title="object&#40;&#123;&#10;  sec-core   &#61; string&#10;  audit-logs &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [vpc_sc_access_levels](variables.tf#L163) | VPC SC access level definitions. | <code title="map&#40;object&#40;&#123;&#10;  combining_function &#61; optional&#40;string&#41;&#10;  conditions &#61; optional&#40;list&#40;object&#40;&#123;&#10;    device_policy &#61; optional&#40;object&#40;&#123;&#10;      allowed_device_management_levels &#61; optional&#40;list&#40;string&#41;&#41;&#10;      allowed_encryption_statuses      &#61; optional&#40;list&#40;string&#41;&#41;&#10;      require_admin_approval           &#61; bool&#10;      require_corp_owned               &#61; bool&#10;      require_screen_lock              &#61; optional&#40;bool&#41;&#10;      os_constraints &#61; optional&#40;list&#40;object&#40;&#123;&#10;        os_type                    &#61; string&#10;        minimum_version            &#61; optional&#40;string&#41;&#10;        require_verified_chrome_os &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    ip_subnetworks         &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    members                &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    negate                 &#61; optional&#40;bool&#41;&#10;    regions                &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    required_access_levels &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  description &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [vpc_sc_egress_policies](variables.tf#L192) | VPC SC egress policy defnitions. | <code title="map&#40;object&#40;&#123;&#10;  from &#61; object&#40;&#123;&#10;    identity_type &#61; optional&#40;string, &#34;ANY_IDENTITY&#34;&#41;&#10;    identities    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#10;  to &#61; object&#40;&#123;&#10;    operations &#61; optional&#40;list&#40;object&#40;&#123;&#10;      method_selectors &#61; optional&#40;list&#40;string&#41;&#41;&#10;      service_name     &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    resources              &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resource_type_external &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [vpc_sc_ingress_policies](variables.tf#L212) | VPC SC ingress policy defnitions. | <code title="map&#40;object&#40;&#123;&#10;  from &#61; object&#40;&#123;&#10;    access_levels &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    identity_type &#61; optional&#40;string&#41;&#10;    identities    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resources     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#10;  to &#61; object&#40;&#123;&#10;    operations &#61; optional&#40;list&#40;object&#40;&#123;&#10;      method_selectors &#61; optional&#40;list&#40;string&#41;&#41;&#10;      service_name     &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    resources &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [vpc_sc_perimeters](variables.tf#L233) | VPC SC regular perimeter definitions for shielded folder. All projects in the perimeter will be added. | <code title="object&#40;&#123;&#10;  access_levels    &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  egress_policies  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  ingress_policies &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

<!-- END TFDOC -->
