# Organization bootstrap

The primary purpose of this stage is to enable critical organization-level functionalities that depend on broad administrative permissions, and prepare the prerequisites needed to enable automation in this and future stages.

It is intentionally simple, to minimize usage of administrative-level permissions and enable simple auditing and troubleshooting, and only deals with three sets of resources:

- project, service accounts, and GCS buckets for automation
- projects, BQ datasets, and sinks for audit log and billing exports
- IAM bindings on the organization

Use the following diagram as a simple high level reference for the following sections, which describe the stage and its possible customizations in detail.

<p align="center">
  <img src="diagram.png" alt="Organization-level diagram">
</p>

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
  - [User groups](#user-groups)
  - [Organization-level IAM](#organization-level-iam)
  - [Organization policies](#organization-policies)
    - [Security Command Center Enterprise](#security-command-center-enterprise)
    - [Tags and Organization Policy conditions](#tags-and-organization-policy-conditions)
  - [Automation project and resources](#automation-project-and-resources)
  - [Billing account](#billing-account)
  - [Organization-level logging](#organization-level-logging)
  - [Naming](#naming)
  - [Workforce Identity Federation](#workforce-identity-federation)
  - [Workload Identity Federation and CI/CD](#workload-identity-federation-and-cicd)
- [How to run this stage](#how-to-run-this-stage)
  - [Prerequisites](#prerequisites)
    - [Standalone billing account](#standalone-billing-account)
    - [Preventing creation of billing-related IAM bindings](#preventing-creation-of-billing-related-iam-bindings)
    - [Groups](#groups)
    - [Configure variables](#configure-variables)
  - [Output files and cross-stage variables](#output-files-and-cross-stage-variables)
  - [Running the stage](#running-the-stage)
- [Customizations](#customizations)
  - [Group names](#group-names)
  - [IAM](#iam)
  - [Log sinks and log destinations](#log-sinks-and-log-destinations)
  - [Names and naming convention](#names-and-naming-convention)
  - [Workload Identity Federation](#workload-identity-federation)
  - [Project folders](#project-folders)
  - [CI/CD repositories](#cicd-repositories)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Design overview and choices

As mentioned above, this stage only does the bare minimum required to bootstrap automation, and ensure that base audit and billing exports are in place from the start to provide some measure of accountability, even before the security configurations are applied in a later stage.

It also sets up organization-level IAM bindings so the Organization Administrator role is only used here, trading off some design freedom for ease of auditing and troubleshooting, and reducing the risk of costly security mistakes down the line. The only exception to this rule is for the [Resource Management stage](../1-resman) service account, described below.

### User groups

User groups are important, not only here but throughout the whole automation process. They provide a stable frame of reference that allows decoupling the final set of permissions for each group, from the stage where entities and resources are created and their IAM bindings defined. For example, the final set of roles for the networking group is contributed by this stage at the organization level (XPN Admin, Cloud Asset Viewer, etc.), and by the Resource Management stage at the folder level.

We have standardized the initial set of groups on those outlined in the [GCP Enterprise Setup Checklist](https://cloud.google.com/docs/enterprise/setup-checklist) to simplify adoption. They provide a comprehensive and flexible starting point that can suit most users. Adding new groups, or deviating from the initial setup is  possible and reasonably simple, and it's briefly outlined in the customization section below.

### Organization-level IAM

The service account used in the [Resource Management stage](../1-resman) needs to be able to grant specific permissions at the organizational level, to enable specific functionality for subsequent stages that deal with network or security resources, or billing-related activities.

In order to be able to assign those roles without having the full authority of the Organization Admin role, this stage defines a custom role that only allows setting IAM policies on the organization, and grants it via a [delegated role grant](https://cloud.google.com/iam/docs/setting-limits-on-granting-roles) that only allows it to be used to grant a limited subset of roles.

In this way, the Resource Management service account can effectively act as an Organization Admin, but only to grant the specific roles it needs to control.

One consequence of the above setup is the need to configure IAM bindings that can be assigned via the condition as non-authoritative, since those same roles are effectively under the control of two stages: this one and Resource Management. Using authoritative bindings for these roles (instead of non-authoritative ones) would generate potential conflicts, where each stage could try to overwrite and negate the bindings applied by the other at each `apply` cycle.

A full reference of IAM roles managed by this stage [is available here](./IAM.md).

### Organization policies

It's often desirable to have organization policies deployed before any other resource in the org, so as to ensure compliance with specific requirements (e.g. location restrictions), or control the configuration of specific resources (e.g. default network at project creation or service account grants).

To cover this use case, organization policies have been moved from the resource management to the bootstrap stage in FAST versions after 26.0.0. They are managed via the usual factory approach, and a [sample set of data files](./data/org-policies/) is included with this stage. They are not applied during the initial run when the `bootstrap_user` variable is set, to work around incompatibilities with user credentials.

The only current exception to the factory approach is the `iam.allowedPolicyMemberDomains` constraint (DRS), which is managed in code so as to be able to auto-allow the organization's domain. More domains can be added via the `org_policies_config` variable, which also serves as an umbrella for future policies that will need to be managed in code.

#### Security Command Center Enterprise

The DRS policy mentioned above might make it complex to [enable Security Command Center Enterprise](https://cloud.google.com/security-command-center/docs/activate-enterprise-tier#verify_organization_policies). If this is the case, you can temporarily disable it via the Cloud Console, enable SCC Enterprise, then re-enable the policy.

#### Tags and Organization Policy conditions

Organization policy exceptions are managed via a dedicated resource management tag hierarchy, rooted in the `org-policies` tag key. A default condition is already present for the the `iam.allowedPolicyMemberDomains` constraint, that relaxes the policy on resources that have the `org-policies/allowed-policy-member-domains-all` tag value bound or inherited, and similarly for `essentialcontacts.allowedContactDomains` via the `allowed-essential-contacts-domains-all` tag value.

Further tag values can be defined via the `org_policies_config.tag_values` variable, and IAM access can be granted on them via the same variable. Once a tag value has been created, its id can be used in constraint rule conditions. Note that only one tag value from a given tag key can be bound to a node (organization, folder, or project) in the resource hierarchy. Since these tag values are all rooted in the `org-policies` key, this limits the ability to apply fine-grained policy constraints. It may be more desirable to model policy overrides using coarser groups of tag values to create a policy "profile". For example, instead of separating `compute.skipDefaultNetworkCreation` and `compute.vmExternalIpAccess`, enforce both constraints by default and relax them both using the same tag value such as `sandbox`. See [tags overview](https://cloud.google.com/resource-manager/docs/tags/tags-overview) for more information.

Management of the rest of the tag hierarchy is delegated to the resource management stage, as that is often intimately tied to the folder hierarchy design.

The organization policy tag key and values managed by this stage have been added to the `0-bootstrap.auto.tfvars` stage, so that IAM can be delegated to the resource management or successive stages via their ids.

The following example shows an example on how to define an additional tag value, and use it in a boolean constraint rule.

This snippet defines a new tag value under the `org-policies` tag key via the `org_policies_config` variable, and assigns the permission to bind it to a group.

```hcl
# stage 0 custom tfvars
org_policies_config = {
  tag_values = {
    compute-require-oslogin-false = {
      description = "Bind this tag to set oslogin to false."
      iam = {
        "roles/resourcemanager.tagUser" = [
          "group:foo@example.com"
        ]
      }
    }
  }
}
# tftest skip
```

The above tag can be used to define a constraint condition via the `data/org-policies/compute.yaml` or similar factory file. The id in the condition is the organization id, followed by the name of the organization policy tag key (defaults to `org-policies`).

```yaml
compute.requireOsLogin:
  rules:
  - enforce: true
  - enforce: false
    condition:
      expression: resource.matchTag('12345678/org-policies-config', 'compute-require-oslogin-false')
```

### Automation project and resources

One other design choice worth mentioning here is using a single automation project for all foundational stages. We trade off some complexity on the API side (single source for usage quota, multiple service activation) for increased flexibility and simpler operations, while still effectively providing the same degree of separation via resource-level IAM.

### Billing account

We support three use cases in regards to billing:

- the billing account is part of this same organization, IAM bindings will be set at the organization level
- the billing account is not considered part of an organization (even though it might be), billing IAM bindings are set on the billing account itself
- billing IAM is managed separately, and no bindings should (or can) be set via Terraform, this requires a few extra steps and is definitely not recommended and mainly used for development purposes

For same-organization billing, we configure a custom organization role that can set IAM bindings, via a delegated role grant to limit its scope to the relevant roles.

For details on configuring the different billing account modes, refer to the [How to run this stage](#how-to-run-this-stage) section below.

Because of limitations of API availability, manual steps have to be followed to enable billing export within billing project to BigQuery dataset `billing_export` which will be created as part of the bootstrap stage. The process to share billing data [is outlined here](https://cloud.google.com/billing/docs/how-to/export-data-bigquery-setup#enable-bq-export).

### Organization-level logging

We create organization-level log sinks early in the bootstrap process to ensure a proper audit trail is in place from the very beginning. By default, we provide log filters to capture [Cloud Audit Logs](https://cloud.google.com/logging/docs/audit), [VPC Service Controls violations](https://cloud.google.com/vpc-service-controls/docs/troubleshooting#vpc-sc-errors) and [Workspace Logs](https://cloud.google.com/logging/docs/audit/configure-gsuite-audit-logs) into logging buckets in the top-level audit logging project.

An organization-level sink captures IAM data access logs, including authentication and impersonation events for service accounts. To manage logging costs, the default configuration enables IAM data access logging only within the automation project (where sensitive service accounts reside). For enhanced security across the entire organization, consider enabling these logs at the organization level.

The [Customizations](#log-sinks-and-log-destinations) section explains how to change the logs captured and their destination.

### Naming

We are intentionally not supporting random prefix/suffixes for names, as that is an antipattern typically only used in development. It does not map to our customer's actual production usage, where they always adopt a fixed naming convention.

What is implemented here is a fairly common convention, composed of tokens ordered by relative importance:

- an organization-level static prefix less or equal to 9 characters (e.g. `myco` or `myco-gcp`)
- an optional tenant-level prefix, if using tenant factory
- an environment identifier (e.g. `prod`)
- a team/owner identifier (e.g. `sec` for Security)
- a context identifier (e.g. `core` or `kms`)
- an arbitrary identifier used to distinguish similar resources (e.g. `0`, `1`)

> [!WARNING]
> When using tenant factory, a tenant prefix will be automatically generated as `{prefix}-{tenant-shortname}`. The maximum length of such prefix must be 11 characters or less, which means that the longer org-level prefix you use, the less chars you'll have available for the `tenant-shortname`.

Tokens are joined by a `-` character, making it easy to separate the individual tokens visually, and to programmatically split them in billing exports to derive initial high-level groupings for cost attribution.

The convention is used in its full form only for specific resources with globally unique names (projects, GCS buckets). Other resources adopt a shorter version for legibility, as the full context can always be derived from their project.

The [Customizations](#names-and-naming-convention) section on names below explains how to configure tokens, or implement a different naming convention.

### Workforce Identity Federation

This stage supports configuration of [Workforce Identity Federation](https://cloud.google.com/iam/docs/workforce-identity-federation) which lets an external identity provider (IdP) to authenticate and authorize a group of users (usually employees) using IAM, so that the users can access Google Cloud services.

The following example shows an example on how to define a Workforce Identity pool for the organization.

```hcl
# stage 0 wif tfvars
workforce_identity_providers = {
  test = {
    issuer       = "azuread"
    display_name = "wif-provider"
    description  = "Workforce Identity pool"
    saml         = {
      idp_metadata_xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>..."
    }
  }
}
# tftest skip
```

### Workload Identity Federation and CI/CD

This stage also implements initial support for two interrelated features

- configuration of [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation) pools and providers
- configuration of CI/CD repositories to allow impersonation via Workload identity Federation, and stage running via provided workflow templates

Workload Identity Federation support allows configuring external providers independently from CI/CD, and offers predefined attributes for a few well known ones (more can be easily added by editing the `identity-providers.tf` file). Once providers have been configured their names are passed to the following stages via interface outputs, and can be leveraged to set up access or impersonation in IAM bindings.

CI/CD support is fully implemented for GitHub, Gitlab, and Cloud Source Repositories / Cloud Build. For GitHub, we also offer a [separate supporting setup](../../extras/0-cicd-github/) to quickly create / configure repositories. The same applies for Gitlab with the [following extra stage](../../extras/0-cicd-gitlab/).

<!-- TODO: add a general overview of our design -->

For details on how to configure both features, refer to the Customizations sections below on [Workload Identity Federation](#workload-identity-federation) and [CI/CD repositories](#cicd-repositories).

These features are optional and only enabled if the relevant variables have been populated.

## How to run this stage

This stage has straightforward initial requirements, as it is designed to work on newly created GCP organizations. Four steps are needed to bring up this stage:

- an Organization Admin self-assigns the required roles listed below
- the same administrator runs the first `init/apply` sequence passing a special variable to `apply`
- the providers configuration file is derived from the Terraform output or linked from the generated file
- a second `init` is run to migrate state, and from then on, the stage is run via impersonation

### Prerequisites

The roles that the Organization Admin used in the first `apply` needs to self-grant are:

- Billing Account Administrator (`roles/billing.admin`)
  either on the organization or the billing account (see the following section for details)
- Logging Admin (`roles/logging.admin`)
- Organization Role Administrator (`roles/iam.organizationRoleAdmin`)
- Organization Administrator (`roles/resourcemanager.organizationAdmin`)
- Project Creator (`roles/resourcemanager.projectCreator`)
- Tag Admin (`roles/resourcemanager.tagAdmin`)
- Owner (`roles/owner`)

To quickly self-grant the above roles, run the following code snippet as the initial Organization Admin:

```bash
# set variable for current logged in user
export FAST_BU=$(gcloud config list --format 'value(core.account)')

# find and set your org id
gcloud organizations list
export FAST_ORG_ID=123456

# set needed roles
export FAST_ROLES="roles/billing.admin roles/logging.admin \
  roles/iam.organizationRoleAdmin roles/resourcemanager.projectCreator \
  roles/resourcemanager.organizationAdmin roles/resourcemanager.tagAdmin \
  roles/owner"

for role in $FAST_ROLES; do
  gcloud organizations add-iam-policy-binding $FAST_ORG_ID \
    --member user:$FAST_BU --role $role --condition None
done
```

Then make sure the same user is also part of the `gcp-organization-admins` group so that impersonating the automation service account later on will be possible.

#### Standalone billing account

If you are using a standalone billing account, the identity applying this stage for the first time needs to be a billing account administrator:

```bash
export FAST_BILLING_ACCOUNT_ID=ABCD-01234-ABCD
gcloud beta billing accounts add-iam-policy-binding $FAST_BILLING_ACCOUNT_ID \
  --member user:$FAST_BU --role roles/billing.admin
```

#### Preventing creation of billing-related IAM bindings

This configuration is possible but unsupported and only present for development purposes, use at your own risk:

- configure `billing_account.id` as `null` and `billing_account.no_iam` to `true` in your `tfvars` file
- apply with `terraform apply -target 'module.automation-project.google_project.project[0]'` in addition to the initial user variable
- once Terraform raises an error run `terraform untaint 'module.automation-project.google_project.project[0]'`
- repeat the two steps above for `'module.log-export-project.google_project.project[0]'`
- go through the process to associate the billing account with the two projects
- configure `billing_account.id` with the real billing account id
- resume applying normally

#### Groups

Before the first run, the following IAM groups must exist to allow IAM bindings to be created (actual names are flexible, see the [Customization](#customizations) section):

- `gcp-billing-admins`
- `gcp-devops`
- `gcp-vpc-network-admins`
- `gcp-organization-admins`
- `gcp-security-admins`

You can refer to [this animated image](./groups.gif) for a step by step on group creation via the [Google Cloud Enterprise Checklist](https://cloud.google.com/docs/enterprise/setup-checklist).

Please note that not all groups defined by the Checklist are actually used by FAST, as our approach to IAM is slightly different. As an example, we do not centralize monitoring functions as in our experience those are typically domain-specific (e.g. networking or application-level), so we don't leverage the corresponding groups. You are free of course to create those groups via the Checklist, and assign them roles via the IAM variables exposed by this stage.

One more difference compared to the Checklist is the use in FAST of an additional group to centralize support functions like viewing tickets and accessing logging and monitoring data. To remain consistent with the [Google Cloud Enterprise Checklist](https://cloud.google.com/docs/enterprise/setup-checklist) we map these permissions to the `gcp-devops` group by default. However, we recommend creating a dedicated `gcp-support` group and updating the `groups` variable with the right value.

#### Configure variables

Then make sure you have configured the correct values for the following variables by providing a `terraform.tfvars` file:

- `billing_account`
  an object containing `id` as the id of your billing account, derived from the Cloud Console UI or by running `gcloud beta billing accounts list`, and the `is_org_level` flag that controls whether organization or account-level bindings are used, and a billing export project and dataset are created
- `groups`
  the name mappings for your groups, if you're following the default convention you can leave this to the provided default
- `organization.id`, `organization.domain`, `organization.customer_id`
  the id, domain and customer id of your organization, derived from the Cloud Console UI or by running `gcloud organizations list`
- `prefix`
  the fixed org-level prefix used in your naming, maximum 9 characters long. Note that if you are using multitenant stages, then you will later need to configure a `tenant prefix`.
  This `tenant prefix` can have a maximum length of 2 characters,
  plus any unused characters from the from the `prefix`.
  For example, if you specify a `prefix` that is 7 characters long,
  then your `tenant prefix` can have a maximum of 4 characters.

You can also adapt the example that follows to your needs:

```tfvars
# use `gcloud beta billing accounts list`
# if you have too many accounts, check the Cloud Console :)
billing_account = {
 id              = "012345-67890A-BCDEF0"
}

# use `gcloud organizations list`
organization = {
 domain      = "example.org"
 id          = 1234567890
 customer_id = "C000001"
}

# local path to store tfvars/provider outputs generated by this stage
outputs_location = "~/fast-config"

# locations for GCS, BigQuery, and logging buckets created here
locations = {
  bq      = "EU"
  gcs     = "EU"
  logging = "global"
  pubsub  = []
}

# use something unique and no longer than 9 characters
prefix = "abcd"
```

### Output files and cross-stage variables

Each foundational FAST stage generates provider configurations and variable files can be consumed by the following stages, and saves them in a dedicated GCS bucket in the automation project. These files are a handy way to simplify stage configuration, and are also used by our CI/CD workflows to configure the repository files in the pipelines that validate and apply the code.

Alongside the GCS stored files, you can also configure a second copy to be saves on the local filesystem, as a convenience when developing or bringing up the infrastructure before a proper CI/CD setup is in place.

This second set of files is disabled by default, you can enable it by setting the `outputs_location` variable to a valid path on a local filesystem, e.g.

```tfvars
outputs_location = "~/fast-config"
```

Once the variable is set, `apply` will generate and manage providers and variables files, including the initial one used for this stage after the first run. You can then link these files in the relevant stages, instead of manually transferring outputs from one stage, to Terraform variables in another.

Below is the outline of the output files generated by all stages, which is identical for both the GCS and local filesystem copies:

```bash
[path specified in outputs_location]
├── providers
│   ├── 0-bootstrap-providers.tf
│   ├── 1-resman-providers.tf
│   ├── 2-networking-providers.tf
│   ├── 2-security-providers.tf
│   ├── 2-project-factory-dev-providers.tf
│   ├── 2-project-factory-prod-providers.tf
│   └── 9-sandbox-providers.tf
└── tfvars
│   ├── 0-bootstrap.auto.tfvars.json
│   ├── 1-resman.auto.tfvars.json
│   ├── 2-networking.auto.tfvars.json
│   └── 2-security.auto.tfvars.json
└── workflows
    └── [optional depending on the configured CI/CD repositories]
```

### Running the stage

Before running `init` and `apply`, check your environment so no extra variables that might influence authentication are present (e.g. `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT`). In general you should use user application credentials, and FAST will then take care to provision automation identities and configure impersonation for you.

When running the first `apply` as a user, you need to pass a special runtime variable so that the user roles are preserved when setting IAM bindings.

```bash
terraform init
terraform apply \
  -var bootstrap_user=$(gcloud config list --format 'value(core.account)')
```

> If you see an error related to project name already exists, please make sure the project name is unique or the project was not deleted recently

Once the initial `apply` completes successfully, configure a remote backend using the new GCS bucket, and impersonation on the automation service account for this stage. To do this you can use the generated `providers.tf` file from either

- the local filesystem if you have configured output files as described above
- the GCS bucket where output files are always stored
- Terraform outputs (not recommended as it's more complex)

The following two snippets show how to leverage the `stage-links.sh` script in the root FAST folder to fetch the commands required for output files linking or copying, using either the local output folder configured via Terraform variables, or the GCS bucket which can be derived from the `automation` output.

```bash
../../stage-links.sh ~/fast-config

# copy and paste the following commands for '0-bootstrap'

ln -s ~/fast-config/providers/0-bootstrap-providers.tf ./
```

```bash
../../stage-links.sh gs://xxx-prod-iac-core-outputs-0

# copy and paste the following commands for '0-bootstrap'

gcloud storage cp gs://xxx-prod-iac-core-outputs-0/providers/0-bootstrap-providers.tf ./
```

Copy/paste the command returned by the script to link or copy the provider file, then migrate state with `terraform init` and run `terraform apply`. If your organization was created with "Secure by Default Org Policy", that is with some of the org policies enabled, add `-var 'org_policies_config={"import_defaults": true}'` to `terraform apply`:

```bash
terraform init -migrate-state
terraform apply
```

or

```bash
terraform init -migrate-state
terraform apply -var 'org_policies_config={"import_defaults": true}'
```

if there default policies are enabled.

Make sure the user you're logged in with is a member of the `gcp-organization-admins` group or impersonation will not be possible.

## Customizations

Most variables (e.g. `billing_account` and `organization`) are only used to input actual values and should be self-explanatory. The only meaningful customizations that apply here are groups, and IAM roles.

### Group names

As we mentioned above, groups reflect the convention used in the [GCP Enterprise Setup Checklist](https://cloud.google.com/docs/enterprise/setup-checklist), with an added level of indirection: the `groups` variable maps logical names to actual names, so that you don't need to delve into the code if your group names do not comply with the checklist convention.

For example, if your network admins team is called `net-rockstars@example.com`, simply set that name in the variable, minus the domain which is interpolated internally with the organization domain:

```hcl
variable "groups" {
  description = "Group names to grant organization-level permissions."
  type        = map(string)
  default = {
    gcp-network-admins = "net-rockstars"
    # [...]
  }
}
# tftest skip
```

If your groups layout differs substantially from the checklist, define all relevant groups in the `groups` variable, then rearrange IAM roles in the code to match your setup.

### IAM

One other area where we directly support customizations is IAM. The code here, as in all stages, follows a simple pattern derived from best practices:

- operational roles for humans are assigned to groups
- any other principal is a service account

In code, the distinction above reflects on how IAM bindings are specified in the underlying module variables:

- group roles "for humans" always use `iam_groups` variables
- service account roles always use `iam` variables

This makes it easy to tweak user roles by adding mappings to the `iam_groups` variables of the relevant resources, without having to understand and deal with the details of service account roles.

One more critical difference in IAM bindings is between authoritative and additive:

- authoritative bindings have complete control on principals for a given role; this is the recommended best practice when a single automation actor controls the role, as it removes drift each time Terraform runs
- additive bindings have control only on given role/principal pairs, and need to be used whenever multiple automation actors need to control the role, as is the case for the network user role in Shared VPC setups, and many other situations

This stage groups all IAM definitions in the [organization-iam.tf](./organization-iam.tf) file, to allow easy parsing of roles assigned to each group and machine identity.

When customizations are needed, three stage-level variables allow injecting additional bindings to match the desired setup:

- `group_iam` allows adding authoritative bindings for groups
- `iam` allows adding authoritative bindings for any type of supported principal, and is merged with the internal `iam` local and then with group bindings at the module level
- `iam_bindings_additive` allows adding individual role/member pairs, and also supports IAM conditions

Refer to the [project module](../../../modules/project/) for examples on how to use the IAM variables, and they are an interface shared across all our modules.

### Log sinks and log destinations

You can customize organization-level logs through the `log_sinks` variable in two ways:

- creating additional log sinks to capture more logs
- changing the destination of captured logs

By default, all logs are exported to a log bucket, but FAST can create sinks to BigQuery, GCS, or PubSub.

If you need to capture additional logs, please refer to GCP's documentation on [scenarios for exporting logging data](https://cloud.google.com/architecture/exporting-stackdriver-logging-for-security-and-access-analytics), where you can find ready-made filter expressions for different use cases.

When using Pubsub or BigQuery destinations, make sure the read-only stage service account (`prefix-prod-bootstrap-0r@prefix-prod-iac-core-0.iam.gserviceaccount.com`) has the necessary permissions to view destination resources. You can add them manually via the authoritative `iam` or the additive `iam_bindings_additive` variables. Refer to issue [#2540](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/issues/2540) for a discussion on this topic, and simple commands to verify proper permissions have been added.

### Names and naming convention

Configuring the individual tokens for the naming convention described above, has varying degrees of complexity:

- the static prefix can be set via the `prefix` variable once
- the environment identifier is set to `prod` as resources here influence production and are considered as such, and can be changed in `main.tf` locals

All other tokens are set directly in resource names, as providing abstractions to manage them would have added too much complexity to the code, making it less readable and more fragile.

If a different convention is needed, identify names via search/grep (e.g. with `^\s+name\s+=\s+"`) and change them in an editor: it should take a couple of  minutes at most, as there's just a handful of modules and resources to change.

Names used in internal references (e.g. `module.foo-prod.id`) are only used by Terraform and do not influence resource naming, so they are best left untouched to avoid having to debug complex errors.

### Workload Identity Federation

At any time during this stage's lifecycle you can configure a Workload Identity Federation pool, and one or more providers. These are part of this stage's interface, included in the automatically generated `.tfvars` files and accepted by the Resource Managent stage that follows.

The variable maps each provider's `issuer` attribute with the definitions in the `identity-providers.tf` file. We currently support GitHub and Gitlab directly, and extending to definitions to support more providers is trivial (send us a PR if you do!).

Provider key names are used by the `cicd_repositories` variable to configure authentication for CI/CD repositories, and generally from your Terraform code whenever you need to configure IAM access or impersonation for federated identities.

This is a sample configuration of a GitHub and a Gitlab provider. Every parameter is optional.

The `custom_settings` attributes are used to configure the provider to work with privately managed installations of Github and Gitlab:

- `issuer_uri` (defaults to the public platforms one if not set)
- `audience` (defaults to the public URL of the provider if not set, as recommended in the [WIF FAQ section](https://cloud.google.com/iam/docs/best-practices-for-using-workload-identity-federation#provider-audience))
- `jwks_json` for public key upload

```tfvars
workload_identity_providers = {
  # Use the public GitHub and specify an attribute condition
  github-public-sample = {
    attribute_condition = "attribute.repository_owner==\"my-github-org\""
    issuer              = "github"
  }
  # Use a private instance of Gitlab and specify a custom issuer_uri
  gitlab-private-sample = {
    issuer              = "gitlab"
    custom_settings     = {
      issuer_uri = "https://gitlab.fast.example.com"
    }
  }
  # Use a private instance of Gitlab.
  # Specify a custom audience and a custom issuer_uri
  gitlab-private-aud-sample = {
    attribute_condition = "attribute.namespace_path==\"my-gitlab-org\""
    issuer              = "gitlab"
    custom_settings = {
      audiences = ["https://gitlab.fast.example.com"]
      issuer_uri        = "https://gitlab.fast.example.com"
    }
  }
}
```

### Project folders

By default this stage creates all its projects directly under the orgaization node. If desired, projects can be moved under a folder using the `project_parent_ids` variable.

```tfvars
project_parent_ids = {
  automation = "folders/1234567890"
  billing    = "folders/9876543210"
  logging    = "folders/1234567890"
}
```

### CI/CD repositories

FAST is designed to directly support running in automated workflows from separate repositories for each stage. The `cicd_repositories` variable allows you to configure impersonation from external repositories leveraging Workload identity Federation, and pre-configures a FAST workflow file that can be used to validate and apply the code in each repository.

The repository design we support is fairly simple, with a repository for modules that enables centralization and versioning, and one repository for each stage optionally configured from the previous stage.

This is an example of configuring the bootstrap and resource management repositories in this stage. CI/CD configuration is optional, so the entire variable or any of its attributes can be set to null if not needed.

```tfvars
cicd_repositories = {
  bootstrap = {
    branch            = null
    identity_provider = "github-sample"
    name              = "my-gh-org/fast-bootstrap"
    type              = "github"
  }
  resman = {
    branch            = "main"
    identity_provider = "github-sample"
    name              = "my-gh-org/fast-resman"
    type              = "github"
  }
}
```

The `type` attribute can be set to one of the supported repository types: `github` or `gitlab`.

Once the stage is applied the generated output files will contain pre-configured workflow files for each repository, that will use Workload Identity Federation via a dedicated service account for each repository to impersonate the automation service account for the stage.

You can use Terraform to automate creation of the repositories using the extra stage defined in [fast/extras/0-cicd-github](../../extras/0-cicd-github/) (only for Github for now).

The remaining configuration is manual, as it regards the repositories themselves:

- create a repository for modules
  - clone and populate it with the Fabric modules
  - configure authentication to the modules repository
    - for GitHub
      - create a key pair
      - create a [deploy key](https://docs.github.com/en/developers/overview/managing-deploy-keys#deploy-keys) in the modules repository with the public key
      - create a `CICD_MODULES_KEY` secret with the private key in each of the repositories that need to access modules (for Gitlab, please Base64 encode the private key for masking)
    - for Gitlab
      - TODO
    - for Source Repositories
      - assign the reader role to the CI/CD service accounts
- create one repository for each stage
  - do an initial apply cycle for the stage so that state exists
  - clone and populate them with the stage source
  - edit the modules source to match your modules repository
    - a simple way is using the "Replace in files" function of your editor
      - search for `source\s*= "../../../modules/([^"]+)"`
      - replace with:
        - modules stored on GitHub: `source = "git@github.com:my-org/fast-modules.git//$1?ref=v1.0"`
        - modules stored on Gitlab: `source = "git::ssh://git@gitlab.com/my-org/fast-modules.git//$1?ref=v1.0"`
        - modules stored on Source Repositories: `"source = git::https://source.developers.google.com/p/my-project/r/my-repository//$1?ref=v1.0"`. You may need to run `git config --global credential.'https://source.developers.google.com'.helper gcloud.sh` first as documented [here](https://cloud.google.com/source-repositories/docs/adding-repositories-as-remotes#add_the_repository_as_a_remote)
  - copy the generated workflow file for the stage from the GCS output files bucket or from the local clone if enabled
    - for GitHub, place it in a `.github/workflows` folder in the repository root
    - for Gitlab, rename it to `.gitlab-ci.yml` and place it in the repository root
    - for Source Repositories, place it in `.cloudbuild/workflow.yaml`

<!-- TFDOC OPTS files:1 show_extra:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [automation.tf](./automation.tf) | Automation project and resources. | <code>gcs</code> · <code>iam-service-account</code> · <code>project</code> |  |
| [billing.tf](./billing.tf) | Billing export project and dataset. | <code>bigquery-dataset</code> · <code>project</code> | <code>google_billing_account_iam_member</code> |
| [checklist.tf](./checklist.tf) | None | <code>gcs</code> | <code>google_storage_bucket_object</code> |
| [cicd.tf](./cicd.tf) | Workload Identity Federation configurations for CI/CD. | <code>iam-service-account</code> |  |
| [identity-providers-defs.tf](./identity-providers-defs.tf) | Identity provider definitions. |  |  |
| [identity-providers.tf](./identity-providers.tf) | Workload Identity Federation provider definitions. |  | <code>google_iam_workforce_pool</code> · <code>google_iam_workforce_pool_provider</code> · <code>google_iam_workload_identity_pool</code> · <code>google_iam_workload_identity_pool_provider</code> |
| [log-export.tf](./log-export.tf) | Audit log project and sink. | <code>bigquery-dataset</code> · <code>gcs</code> · <code>logging-bucket</code> · <code>project</code> · <code>pubsub</code> |  |
| [main.tf](./main.tf) | Module-level locals and resources. |  |  |
| [organization-iam.tf](./organization-iam.tf) | Organization-level IAM bindings locals. |  |  |
| [organization.tf](./organization.tf) | Organization-level IAM. | <code>organization</code> |  |
| [outputs-files.tf](./outputs-files.tf) | Output files persistence to local filesystem. |  | <code>local_file</code> |
| [outputs-gcs.tf](./outputs-gcs.tf) | Output files persistence to automation GCS bucket. |  | <code>google_storage_bucket_object</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [billing_account](variables.tf#L17) | Billing account id. If billing account is not part of the same org set `is_org_level` to `false`. To disable handling of billing IAM roles set `no_iam` to `true`. | <code title="object&#40;&#123;&#10;  id           &#61; string&#10;  is_org_level &#61; optional&#40;bool, true&#41;&#10;  no_iam       &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [organization](variables.tf#L261) | Organization details. | <code title="object&#40;&#123;&#10;  id          &#61; number&#10;  domain      &#61; optional&#40;string&#41;&#10;  customer_id &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [prefix](variables.tf#L276) | Prefix used for resources that need unique names. Use 9 characters or less. | <code>string</code> | ✓ |  |  |
| [bootstrap_user](variables.tf#L27) | Email of the nominal user running this stage for the first time. | <code>string</code> |  | <code>null</code> |  |
| [cicd_repositories](variables.tf#L33) | CI/CD repository configuration. Identity providers reference keys in the `federated_identity_providers` variable. Set to null to disable, or set individual repositories to null if not needed. | <code title="object&#40;&#123;&#10;  bootstrap &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  resman &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  tenants &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  vpcsc &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |  |
| [custom_roles](variables.tf#L87) | Map of role names => list of permissions to additionally create at the organization level. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [environments](variables.tf#L94) | Environment names. | <code title="map&#40;object&#40;&#123;&#10;  name       &#61; string&#10;  is_default &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  dev &#61; &#123;&#10;    name &#61; &#34;Development&#34;&#10;  &#125;&#10;  prod &#61; &#123;&#10;    name       &#61; &#34;Production&#34;&#10;    is_default &#61; true&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [essential_contacts](variables.tf#L118) | Email used for essential contacts, unset if null. | <code>string</code> |  | <code>null</code> |  |
| [factories_config](variables.tf#L124) | Configuration for the resource factories or external data. | <code title="object&#40;&#123;&#10;  checklist_data    &#61; optional&#40;string&#41;&#10;  checklist_org_iam &#61; optional&#40;string&#41;&#10;  custom_roles      &#61; optional&#40;string, &#34;data&#47;custom-roles&#34;&#41;&#10;  org_policy        &#61; optional&#40;string, &#34;data&#47;org-policies&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [groups](variables.tf#L136) | Group names or IAM-format principals to grant organization-level permissions. If just the name is provided, the 'group:' principal and organization domain are interpolated. | <code title="object&#40;&#123;&#10;  gcp-billing-admins      &#61; optional&#40;string, &#34;gcp-billing-admins&#34;&#41;&#10;  gcp-devops              &#61; optional&#40;string, &#34;gcp-devops&#34;&#41;&#10;  gcp-network-admins      &#61; optional&#40;string, &#34;gcp-vpc-network-admins&#34;&#41;&#10;  gcp-organization-admins &#61; optional&#40;string, &#34;gcp-organization-admins&#34;&#41;&#10;  gcp-security-admins     &#61; optional&#40;string, &#34;gcp-security-admins&#34;&#41;&#10;  gcp-support &#61; optional&#40;string, &#34;gcp-devops&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [iam](variables.tf#L152) | Organization-level custom IAM settings in role => [principal] format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [iam_bindings_additive](variables.tf#L159) | Organization-level custom additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [iam_by_principals](variables.tf#L174) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [locations](variables.tf#L181) | Optional locations for GCS, BigQuery, and logging buckets created here. | <code title="object&#40;&#123;&#10;  bq      &#61; optional&#40;string, &#34;EU&#34;&#41;&#10;  gcs     &#61; optional&#40;string, &#34;EU&#34;&#41;&#10;  logging &#61; optional&#40;string, &#34;global&#34;&#41;&#10;  pubsub  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [log_sinks](variables.tf#L195) | Org-level log sinks, in name => {type, filter} format. | <code title="map&#40;object&#40;&#123;&#10;  filter &#61; string&#10;  type   &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  audit-logs &#61; &#123;&#10;    filter &#61; &#60;&#60;-FILTER&#10;      log_id&#40;&#34;cloudaudit.googleapis.com&#47;activity&#34;&#41; OR&#10;      log_id&#40;&#34;cloudaudit.googleapis.com&#47;system_event&#34;&#41; OR&#10;      log_id&#40;&#34;cloudaudit.googleapis.com&#47;policy&#34;&#41; OR&#10;      log_id&#40;&#34;cloudaudit.googleapis.com&#47;access_transparency&#34;&#41;&#10;    FILTER&#10;    type   &#61; &#34;logging&#34;&#10;  &#125;&#10;  iam &#61; &#123;&#10;    filter &#61; &#60;&#60;-FILTER&#10;      protoPayload.serviceName&#61;&#34;iamcredentials.googleapis.com&#34; OR&#10;      protoPayload.serviceName&#61;&#34;iam.googleapis.com&#34; OR&#10;      protoPayload.serviceName&#61;&#34;sts.googleapis.com&#34;&#10;    FILTER&#10;    type   &#61; &#34;logging&#34;&#10;  &#125;&#10;  vpc-sc &#61; &#123;&#10;    filter &#61; &#60;&#60;-FILTER&#10;      protoPayload.metadata.&#64;type&#61;&#34;type.googleapis.com&#47;google.cloud.audit.VpcServiceControlAuditMetadata&#34;&#10;    FILTER&#10;    type   &#61; &#34;logging&#34;&#10;  &#125;&#10;  workspace-audit-logs &#61; &#123;&#10;    filter &#61; &#60;&#60;-FILTER&#10;      log_id&#40;&#34;cloudaudit.googleapis.com&#47;data_access&#34;&#41; AND&#10;      protoPayload.serviceName&#61;&#34;login.googleapis.com&#34;&#10;    FILTER&#10;    type   &#61; &#34;logging&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [org_policies_config](variables.tf#L243) | Organization policies customization. | <code title="object&#40;&#123;&#10;  constraints &#61; optional&#40;object&#40;&#123;&#10;    allowed_essential_contact_domains &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    allowed_policy_member_domains     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  import_defaults &#61; optional&#40;bool, false&#41;&#10;  tag_name        &#61; optional&#40;string, &#34;org-policies&#34;&#41;&#10;  tag_values &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;    iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    id          &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [outputs_location](variables.tf#L270) | Enable writing provider, tfvars and CI/CD workflow files to local filesystem. Leave null to disable. | <code>string</code> |  | <code>null</code> |  |
| [project_parent_ids](variables.tf#L285) | Optional parents for projects created here in folders/nnnnnnn format. Null values will use the organization as parent. | <code title="object&#40;&#123;&#10;  automation &#61; optional&#40;string&#41;&#10;  billing    &#61; optional&#40;string&#41;&#10;  logging    &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [workforce_identity_providers](variables.tf#L296) | Workforce Identity Federation pools. | <code title="map&#40;object&#40;&#123;&#10;  attribute_condition &#61; optional&#40;string&#41;&#10;  issuer              &#61; string&#10;  display_name        &#61; string&#10;  description         &#61; string&#10;  disabled            &#61; optional&#40;bool, false&#41;&#10;  saml &#61; optional&#40;object&#40;&#123;&#10;    idp_metadata_xml &#61; string&#10;  &#125;&#41;, null&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [workload_identity_providers](variables.tf#L312) | Workload Identity Federation pools. The `cicd_repositories` variable references keys here. | <code title="map&#40;object&#40;&#123;&#10;  attribute_condition &#61; optional&#40;string&#41;&#10;  issuer              &#61; string&#10;  custom_settings &#61; optional&#40;object&#40;&#123;&#10;    issuer_uri &#61; optional&#40;string&#41;&#10;    audiences  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    jwks_json  &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [automation](outputs.tf#L146) | Automation resources. |  |  |
| [billing_dataset](outputs.tf#L151) | BigQuery dataset prepared for billing export. |  |  |
| [cicd_repositories](outputs.tf#L156) | CI/CD repository configurations. |  |  |
| [custom_roles](outputs.tf#L168) | Organization-level custom roles. |  |  |
| [outputs_bucket](outputs.tf#L173) | GCS bucket where generated output files are stored. |  |  |
| [project_ids](outputs.tf#L178) | Projects created by this stage. |  |  |
| [providers](outputs.tf#L188) | Terraform provider files for this stage and dependent stages. | ✓ | <code>stage-01</code> |
| [service_accounts](outputs.tf#L195) | Automation service accounts created by this stage. |  |  |
| [tfvars](outputs.tf#L213) | Terraform variable files for the following stages. | ✓ |  |
| [workforce_identity_pool](outputs.tf#L219) | Workforce Identity Federation pool. |  |  |
| [workload_identity_pool](outputs.tf#L228) | Workload Identity Federation pool and providers. |  |  |
<!-- END TFDOC -->
