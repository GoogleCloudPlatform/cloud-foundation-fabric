# Organization-level bootstrap samples

This set of Terraform root modules is designed with two main purposes in mind: automating the organizational layout, and bootstrapping the initial resources and the corresponding IAM roles, which will then be used to automate the actual infrastructure.

Despite being fairly generic, these modules closely match some of the initial automation stages we have implemented in actual customer engagements, and are purposely kept simple to offer a good starting point for further customizations.

There are several advantages in using an initial stage like the ones provided here:

- automate and parameterize creation of the organizational layout, documenting it through code
- use a single declarative tool to create and manage both prerequisites and the actual infrastructure, eliminating the need for manual commands, scripts or external tools
- enforce separation of duties at the environment (or tenant in multi-tenant architectures) level, by automating creation of per-environment Terraform service accounts, their IAM roles, and GCS buckets to hold state
- decouple and document the use of organization-level permissions from the day to day management of the actual infrastructure, by assigning a minimum but sufficient set of high level IAM roles to Terraform service accounts in an initial stage
- provide a sane place for the creation and management of shared resources that are not tied to a specific environment

## Operational considerations

This specific type of preliminary automation stage is usually fairly static, only changing when a new environment or shared resource is added or modified, and lends itself well to being applied manually by organization administrators. One secondary advantage of running this initial stage manually, is eliminating the need to create and manage automation credentials that embed sensitive permissions scoped at the organization or root folder level.

### IAM roles

This type of automation stage needs very specific IAM roles on the root node (organization or folder), and additional roles at the organization level if the generated service accounts for automation need to be able to create and manage Shared VPC. The needed roles are:

- on the root node Project Creator, Folder Administrator, Logging Administrator
- on the billing account or organization Billing Account Administrator
- on the organization Organization Administrator, if Shared VPC needs to be managed by the automation service accounts

### State

This type of stage creates the prerequisites for Terraform automation including the GCS bucket used for its own remote state, so some care needs to be used when running it for the first time, when its GCS bucket has not yet been created.

After the first successful `terraform apply`, edit `backend.tf.sample` and set the bucket name to the one shown in the `bootstrap_tf_gcs_bucket` output, then save and rename the file to `backend.tf`. Once that is done, run `terraform apply` again to transfer local state to the remote GCS bucket. From then on, state will be remote.

### Things to be aware of

Using `count` in Terraform resources has the [well-known limitation](https://github.com/hashicorp/terraform/issues/18767) that changing the variable controlling `count` results in the potential unwanted deletion of resources.

These samples use `count` on the `environments` list variable to manage multiples for key resources like service accounts, GCS buckets, and IAM roles. Environment names are usually stable, but care must still be taken in defining the initial list so that names are final, and names for temporary environments (if any are needed) are last so they don't trigger recreation of resources based on the following elements in the list.

This issue will be addressed in a future release of these examples, by replacing `count` with the new `foreach` construct [introduced in Terraform 0.12.6](https://twitter.com/mitchellh/status/1156661893789966336?lang=en) that uses key-based indexing.
