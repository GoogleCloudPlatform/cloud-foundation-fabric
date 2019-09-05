# Organization-level bootstrap samples

This set of Terraform root modules is designed with two main purposes in mind: automating the organizational layout, and bootstrapping the initial resources needed to automate the actual infrastructure with their respective IAM roles.

Despite being fairly generic, these modules closely match some of the initial automation stages we have implemented in real life, and are purposely kept simple to offer a good starting point for further customizations.

There are several advantages in using an initial stage for automation such as the ones in these samples:

- automate and parameterize creation of the organizational layout
- use the same declarative tool to create and manage initial resources, as for the rest of the infrastructure, eliminating the need of resorting to manual commands, scripts or external tools
- enforce separation of duties at the environment (or tenant in multi-tenant architectures) level, through the use of per-environment automation service accounts and state buckets
- decouple and document the use of organization-level permissions from the day to day management of the actual infrastructure, by managing the service accounts used for automation and their IAM roles once in an initial stage
- provide a sane place for the creation and management of shared resources that are not tied to a specific environment

## Operational considerations

Such an initial stage is usually fairly static, only changing when a new environment or shared resource is added or modified, and is then well suited for manual application by high-level administrators without the need of plugging it into a pipeline, thus eliminating the need of creating and storing service account keys that embed powerful org-level roles.

### IAM roles

As described above, this type of preliminary stage needs very specific roles on the root node (either the org or a folder), and additional roles at the organization level if the generated service accounts for automation need to be able to create and manage Shared VPC:

- Billing Account Administrator on the billing account or organization
- Folder Administrator
- Logging Administrator on the root folder or organization
- Project Creator
- Organization Administrator, if Shared VPC roles need to be granted

### State

As these stages create the prerequisites for Terraform, they also create the GCS bucket for their own remote state, so some care needs to be used when running them for the first time, when their GCS buckets have not yet been created. This is the sequence of steps to be followed to enable remote state management:

- when running `apply` for the first time, the `backend.tf` file needs to be commented so local state is used
- after the first `apply` has completed successfully, the comments in the `backend.tf` file need to be removed, and the GCS bucket name from the `bootstrap_tf_gcs_bucket` output added as a value for the `bucket` attribute
- once the `bootstrap.tf` file has been updated, `apply` has to be run again so that state is moved from the local file to the remote bucket

The steps above only need to be performed once, after that the chicken-and-eggs problem is solved and state is remote for all subsequent runs.

### Things to be aware of

One potential issue to be aware of is related to Terraform's way of managing multiple resources indexed by positional argument. What could happen in practice is that a change in one of the elements in the `environments` variable could trigger recreation of all the resources dependent on this variable: service accounts, folders, GCS buckets. This is a relatively rare issue as environment names are usually stable, and a later addition of a new element in the list won't have any of the above effects, but it's still worth accounting for. This issue will be addressed in a future version, by using the new `foreach` construct [introduced in Terraform 0.12.6](https://twitter.com/mitchellh/status/1156661893789966336?lang=en).
