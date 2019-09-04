# Business-units based organizational sample

This sample creates an organizational layout with two folder levels, where the first level is usually mapped to one business unit (infra, data, analythics) and the second level represents enviroments (prod, test). It also sets up all prerequisites for automation (GCS state buckets, service accounts, etc.), and the correct roles on those to enforce separation of duties at the environment level.

This layout is well suited for small and medium-sized infrastructures managed by a smal set of teams, where the complexity in application resource ownership and access roles is mostly dealt with at the project level, and/or in the individual services (GKE, Cloud SQL, etc.). Its simplicity also makes it a good starting point for more complex or specialized layouts.

This layout is well suited for medium-sized infrastructures managed by different sets of teams grouped to different business units, where the complexity in application resource ownership and access roles is mostly dealt with at the project level, and/or in the individual services (GKE, Cloud SQL, etc.). 

![High-level diagram](diagram.png "High-level diagram")

This set of Terraform files is usually applied manually by an org-level administrator as a first step, and then reapplied only when a new business-unit or environment needs to be created or an existing one removed, and serves different purposes:

- automating and parameterizing creation of the organizational layout
- automating creation of the base resources needed for Terraform automation, obviating the need for external scripts or hand-coded commands
- anticipating the requirement of organizational-level roles for specific resources (eg Shared VPC), by granting them to the service accounts used for environment automation
- enforcing separation of duties by using separate sets of automation resources (GCS, service accounts) for each environment, and only granting roles scoped to the environment's folder

## Managed resources and services

This sample creates several distinct groups of resources:

- one folder per business unit
- two second-level folders (test, prod) for every business unit
- one top-level project to hold Terraform-related resources
- one top-level project to set up and host centralized audit log exports (optional).
- one top-level project to hold services used across environments like GCS, GCR, KMS, Cloud Build, etc. (optional)

The number of resources in this sample is kept to a minimum so as to make it generally applicable, more resources can be easily added by leveraging the full array of [Cloud Foundation Toolkit modules](https://github.com/terraform-google-modules), especially in the shared services project.

## Operational considerations

As mentioned above this root module is meant to be run infrequently, only when an environment or a shared service needs to be added or changed, so the advantages of automating it in a CI pipeline are very limited.

### IAM roles

Regardless of how it's run, the credentials used need very specific roles on the root node, plus additional roles at the organization level if Shared VPC usage is anticipated in environments:

- Billing Account Administrator on the billing account or organization
- Folder Administrator
- Logging Administrator on the root folder or organization
- Project Creator
- Organization Administrator, if Shared VPC roles need to be granted

### State

TODO: describe the state switch that needs to be done after first apply

### Things to be aware of

TODO: describe potential issues with multiple resources, and the upcoming `foreach` fix
TODO: describe how `prefix` can be used to enforce naming
TODO: describe xpn roles

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| audit\_viewers | Audit project viewers, in IAM format. | list | `<list>` | no |
| billing\_account\_id | Billing account id used as default for new projects. | string | n/a | yes |
| business\_unit\_1\_envs | Business unit 1 environments short names. | list(string) | `<list>` | no |
| business\_unit\_1\_name | Business unit 1 short name. | string | n/a | yes |
| business\_unit\_2\_envs | Business unit 2 environments short names. | list(string) | `<list>` | no |
| business\_unit\_2\_name | Business unit 2 short name. | string | n/a | yes |
| business\_unit\_3\_envs | Business unit 3 environments short names. | list(string) | `<list>` | no |
| business\_unit\_3\_name | Business unit 3 short name. | string | n/a | yes |
| gcs\_location | GCS bucket location. | string | `"EU"` | no |
| generate\_service\_account\_keys | Generate and store service account keys in the state file. | string | `"false"` | no |
| organization\_id | Organization id. | string | n/a | yes |
| prefix | Prefix used for resources that need unique names. | string | n/a | yes |
| project\_services | Service APIs enabled by default in new projects. | list | `<list>` | no |
| root\_node | Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'. | string | n/a | yes |
| shared\_bindings\_members | List of comma-delimited IAM-format members for the additional shared project bindings. | list | `<list>` | no |
| shared\_bindings\_roles | List of roles for additional shared project bindings. | list | `<list>` | no |
| terraform\_owners | Terraform project owners, in IAM format. | list | `<list>` | no |

## Outputs

| Name | Description |
|------|-------------|
| audit\_logs\_bq\_dataset | Bigquery dataset for the audit logs export. |
| audit\_logs\_project | Project that holds the audit logs export resources. |
| bootstrap\_tf\_gcs\_bucket | GCS bucket used for the bootstrap Terraform state. |
| business\_unit\_1\_envs\_folders\_ids | Business unit 1 environment folders. |
| business\_unit\_1\_envs\_service\_account\_keys | Service account keys used to run each environment Terraform modules for business unit 1. |
| business\_unit\_1\_envs\_service\_accounts | Service accounts used to run each environment Terraform modules for business unit 1. |
| business\_unit\_1\_envs\_tf\_gcs\_buckets | GCS buckets used for each environment Terraform state for business unit 1. |
| business\_unit\_1\_top\_level\_folder\_id | Business unit 1 top-level folder. |
| business\_unit\_2\_envs\_folders\_ids | Business unit 2 environment folders. |
| business\_unit\_2\_envs\_service\_account\_keys | Service account keys used to run each environment Terraform modules for business unit 2. |
| business\_unit\_2\_envs\_service\_accounts | Service accounts used to run each environment Terraform modules for business unit 2. |
| business\_unit\_2\_envs\_tf\_gcs\_buckets | GCS buckets used for each environment Terraform state for business unit 2. |
| business\_unit\_2\_top\_level\_folder\_id | Business unit 2 top-level folder. |
| business\_unit\_3\_envs\_folders\_ids | Business unit 3 environment folders. |
| business\_unit\_3\_envs\_service\_account\_keys | Service account keys used to run each environment Terraform modules for business unit 3. |
| business\_unit\_3\_envs\_service\_accounts | Service accounts used to run each environment Terraform modules for business unit 3. |
| business\_unit\_3\_envs\_tf\_gcs\_buckets | GCS buckets used for each environment Terraform state for business unit 3. |
| business\_unit\_3\_top\_level\_folder\_id | Business unit 3 top-level folder. |
| shared\_resources\_project | Project that holdes resources shared across business units. |
| terraform\_project | Project that holds the base Terraform resources. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
