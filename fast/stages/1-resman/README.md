# Resource hierarchy

This stage manages the upper part of the resource management hierarchy, and decouples later stages (networking, etc.) from the organization via folders, IaC resources and IAM bindings.

The complete hierarchy is not managed here, as considerations on departments, teams, and applications are too granular and best managed via the [project factory](../2-project-factory/), which this stage enables.

As many other parts of FAST, this stage implements several factories that allow simplified management and operations of recurring sets of resources.

The following diagram is a high level reference of the resources created and managed here, and gives an initial representation of its three main configuration elements: top-level folders, FAST stage 2s and stage 3s.

<p align="center">
  <img src="diagram.png" alt="Resource-management diagram">
</p>

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
- [Resource management primitives](#resource-management-primitives)
  - [Top-level folders](#top-level-folders)
  - [Stage 2](#stage-2)
  - [Stage 3](#stage-3)
  - [Project and hierarchy factory](#project-and-hierarchy-factory)
- [Other design considerations](#other-design-considerations)
  - [Secure tags](#secure-tags)
  - [Multitenancy](#multitenancy)
  - [Workload Identity Federation and CI/CD](#workload-identity-federation-and-cicd)
- [How to run this stage](#how-to-run-this-stage)
  - [Provider and Terraform variables](#provider-and-terraform-variables)
  - [Impersonating the automation service account](#impersonating-the-automation-service-account)
  - [Variable configuration](#variable-configuration)
  - [Running the stage](#running-the-stage)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Design overview and choices

This stage is designed to offer a good amount of flexibility in laying out the organizational hierarchy, while still providing a default approach that we've seen working across different types of users and organizations.

The default design provided here splits the hierarchy in two different logical areas:

- core or shared resources (e.g. networking) which are grouped in dedicated top-level folders that implement centralized management by dedicated teams
- team or application resources which are grouped under one or more top-level "teams" folders, and typically host managed services (storage, etc.) billed and controlled by their distributed teams

This split approach allows concise mapping of functional and operational patterns to IAM roles and GCP-specific constructs:

- core services are clearly separated, providing few touchpoints where IAM and security policies need to be applied (typically their top-level folder)
- new sets of core services (fleets of VMs, shared GKE clusters, etc.) are added as a unit, minimizing operational complexity
- team and application resources not subject to centralized management are grouped together, providing a unified view and easy budgeting/cost-allocation
- automation for core resources is segregated via separate service accounts and buckets for each area (shared service, application) effectively minimizing blast radius

Resource names follow the FAST convention discussed in the [Bootstrap stage documentation](../0-bootstrap/README.md#naming).

## Resource management primitives

This stage allows a certain degree of free-form hierarchy design on top of instead of the default layout, by providing a set of high level primitives that implement specific FAST functionality: top-level folders, centralized stage 2, environment-level stage 3 for shared services, and the project factory.

### Top-level folders

Top-level folders, as indicated by their name, are folders directly attached to the organization that can be freely defined via Terraform variables or factory YAML files. They represent a node in the organization, which can be used to partition the hierarchy via IAM or tag bindings, and to implement separate automation stages via their optional IaC resources.

Top-level folders offer less direct integration into the FAST workflow and machinery, and are meant to solve specific use cases in addition to our standard stage 2 and 3 described in the following section.

The full interface of the [folder module](../../../modules/folder/) is supported for top-level folders, allowing them to fit in the FAST design in different ways:

- as supporting folders for the project factory, by granting high level permissions to its service accounts via IAM and tag bindings (see the ["Teams" example in the data folder](./data/top-level-folders/teams.yaml))
- as standalone folders for custom usage, with or without associated IaC resources (see the ["Sandbox" exanple in the data folder](./data/top-level-folders/sandbox.yaml))
- as grouping nodes for the environment-specific stage 3 folders (see the ["GCVE" example in the data folder](./data/top-level-folders/gcve.yaml))
- as grouping nodes for stage 2s, for example via a "Shared Services" top-level folder set as the `folder_config.parent_id` attribute for networking and security stages

Top-level folders support context-based expansion for service accounts and organization-level tags, which can be referenced by name (e.g. `project-factory` to refer to the project factory service accounts). This allows writing portable organization-independent YAML that can be shared across different FAST installations.

### Stage 2

FAST stage 2s implement core infrastructure services shared across the organization. In the FAST design networking, security, and the project factory are defined as stage 2. Their interface is sufficiently flexible to allow easy definition of custom stages, which can then be integrated in the framework.

FAST stage 2s are typically managed by dedicated teams, they implement environment separation internally due to the complexity of their designs, and provide resources and specific IAM permissions to other shared services implemented as stage 3s (e.g. Shared VPC networks, IAM delegated grants on host projects/subnets or KMS keys).

The default configuration enables all stage 2s via factory files in the `data/stage-2` folder. Each stage can be customized via a set of variable-level attributes:

- `short_name` defines the name used for the stage IaC resources
- `cicd_config` optionally configures built-in CI/CD support for the stage
- `folder_config` controls the name, organization policies, and IAM profile for the stage folder, and allows defining additional environment-level subfolders
- `organization_config` controls the IAM profile for the stage at the organization level
- `stage3_config` allows defining signals that are passed on to the stage via output variables, on specific IAM configurations needed by stage 3s

Each stage creates its own tag value in the `context` key, which can then be used for conditional roles at the organization level (`context/networking`, `context/project-factory` etc.) when needed. The tag value is assigned to the stage's folder, and can be applied to other folders to enable specific functionality, for example to allow the project factory to manage additional top-level folders.

Think of stage 2s as "named stages" which can define specific IAM configurations on the organization, and are free to define their own environment-level constraints.

### Stage 3

FAST stage 3s are designed to host shared infrastructure that leverages core services from stage 2 (networking, encryption keys, etc.), and is partitioned by environment and subject to environment-level constraints, with no direct access to organization-level IAM configurations.

As shared services they are still managed by dedicated teams, but principals and permissions might differ between environments. Stage 3s typically leverage top-level folders, under which the environment-level folders for the stage are then created.

Configuration can be done either via Terraform variables or factory YAML files. The second option is used by default, providing a set of factory files for top-level folders and stage 3s that mirror the legacy FAST hierarchy implemented via code.

Configuration is similar to the stage 2 one described above, save that stage 3:

- need to define the environment for which they will be deployed
- have no way to configure organization-level IAM

### Project and hierarchy factory

Despite being itself a stage 2 (and potentially one or more environment-specific stage 3), the project factory is an important primitive to shape the lower level resource hierarchy which implements folder and project management.

By default FAST configures a single organization-wide project factory with the following characteristics:

- any top-level folder with the suitable set of roles can be managed as a sub-hierarchy tree by the project factory (see the ["Teams" definition](./data/top-level-folders/teams.yaml) in the data folder)
- organization policy management on its folders and projects by the project factory only requires binding the `context/project-factory` tag value
- networking-related project configuration is available by default, the project factory can grant a limited set of roles on network resources, and attach service projects to VPC host projects
- security-related project configuration is available by default, the project factory can grant the KMS encrypt/decrypt role on centralized KMS key in the security stage

Additional project factories can of course be defined by cloning the default stage 2 configuration, and changing the stage 2 names and folders.

## Other design considerations

### Secure tags

This stage manages [Secure Tags](https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing) at the organization level, via two sets of keys and values:

- a default set of tags used by FAST itself in specific IAM conditions that allow automation service accounts to gain organization-level privileges or specific access to parts of the resource management hierarchy
- an optional set of user-defined tags that can be used in organization policy or IAM conditions

The first set of default tags cannot be overridden and defines the following keys and values (key names can be changed via the `tag_names` variable):

- `context` to identify parts of the resource hierarchy, with `data`, `gke`, `networking`, `sandbox`, `security` and `teams` values
- `environment` to identify folders and projects belonging to specific environments, with `development` and `production` values

The second set is optional and allows defining a custom tag hierarchy, including IAM bindings that can refer to specific identities, or to the internally defined automation service accounts via their names, like in the following example:

```tfvars
tags = {
  my-custom-tag = {
    values = {
      eggs = {}
      spam = {
        description = "Example tag value."
        iam = {
          "roles/resourcemanager.tagUser" = ["sandbox"]
        }
      }
    }
  }
}
```

### Multitenancy

Multitenancy is supported via an [add-on](../../addons/1-resman-tenants/) which is entirely optional, and is be applied after resource management has been deployed. The add-on needs to be enabled before use via the `fast_addon` variable in the bootstrap stage.

For simpler use cases that do not require complex organization-level multitenancy, [top-level folders](#top-level-folders) can be used in combination with the [project factory stage](../2-project-factory/) support for folder and project management.

### Workload Identity Federation and CI/CD

This stage also implements optional support for CI/CD, much in the same way as the bootstrap stage. The only difference is on Workload Identity Federation, which is only configured in bootstrap and made available here via stage interface variables (the automatically generated `.tfvars` files).

For details on how to configure CI/CD please refer to the [relevant section in the bootstrap stage documentation](../0-bootstrap/README.md#cicd-repositories).

## How to run this stage

This stage is meant to be executed after the [bootstrap](../0-bootstrap) stage has run, as it leverages the automation service account and bucket created there. The relevant user groups must also exist, but that's one of the requirements for the previous stage too, so if you ran that successfully, you're good to go.

It's of course possible to run this stage in isolation, but that's outside the scope of this document, and you would need to refer to the code for the bootstrap stage for the actual roles needed.

Before running this stage, you need to make sure you have the correct credentials and permissions, and localize variables by assigning values that match your configuration.

### Provider and Terraform variables

As all other FAST stages, the [mechanism used to pass variable values and pre-built provider files from one stage to the next](../0-bootstrap/README.md#output-files-and-cross-stage-variables) is also leveraged here.

The commands to link or copy the provider and terraform variable files can be easily derived from the `fast-links.sh` script in the FAST stages folder, passing it a single argument with the local output files folder (if configured) or the GCS output bucket in the automation project (derived from stage 0 outputs). The following examples demonstrate both cases, and the resulting commands that then need to be copy/pasted and run.

Using local output files.

```bash
../fast-links.sh ~/fast-config

# File linking commands for resource management stage

# provider file
ln -s ~/fast-config/fast-test-00/providers/1-resman-providers.tf ./

# input files from other stages
ln -s ~/fast-config/fast-test-00/tfvars/0-globals.auto.tfvars.json ./
ln -s ~/fast-config/fast-test-00/tfvars/0-bootstrap.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
ln -s ~/fast-config/fast-test-00/1-resman.auto.tfvars ./
```

Using the GCS outputs bucket.

```bash
../fast-links.sh gs://xxx-prod-iac-core-outputs-0

# File linking commands for resource management stage

# provider file
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/providers/1-resman-providers.tf ./

# input files from other stages
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/1-resman.auto.tfvars ./
```

### Impersonating the automation service account

The preconfigured provider file uses impersonation to run with this stage's automation service account's credentials. The `gcp-devops` and `organization-admins` groups have the necessary IAM bindings in place to do that, so make sure the current user is a member of one of those groups.

### Variable configuration

Variables in this stage -- like most other FAST stages -- are broadly divided into three separate sets:

- variables which refer to global values for the whole organization (org id, billing account id, prefix, etc.), which are pre-populated via the `0-globals.auto.tfvars.json` file linked or copied above
- variables which refer to resources managed by previous stage, which are prepopulated here via the `0-bootstrap.auto.tfvars.json` file linked or copied above
- and finally variables that optionally control this stage's behaviour and customizations, and can to be set in a custom `terraform.tfvars` file

Note that the `outputs_location` variable is disabled by default, you need to explicitly set it in your `terraform.tfvars` file if you want output files to be generated by this stage. This is a sample `terraform.tfvars` that configures it, refer to the [bootstrap stage documentation](../0-bootstrap/README.md#output-files-and-cross-stage-variables) for more details:

```tfvars
outputs_location = "~/fast-config"
```

### Running the stage

Once provider and variable values are in place and the correct user is configured, the stage can be run:

```bash
terraform init
terraform apply
```

<!-- TFDOC OPTS files:1 show_extra:1 exclude:1-resman-providers.tf -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [billing.tf](./billing.tf) | Billing resources for external billing use cases. |  | <code>google_billing_account_iam_member</code> |
| [main.tf](./main.tf) | Module-level locals and resources. |  |  |
| [organization.tf](./organization.tf) | Organization policies. | <code>organization</code> |  |
| [outputs-cicd.tf](./outputs-cicd.tf) | Locals for CI/CD workflow files. |  |  |
| [outputs-files.tf](./outputs-files.tf) | Output files persistence to local filesystem. |  | <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [outputs-providers.tf](./outputs-providers.tf) | Locals for provider output files. |  |  |
| [outputs.tf](./outputs.tf) | Module outputs. |  |  |
| [stage-2.tf](./stage-2.tf) | Stage 2s locals and resources. | <code>folder</code> · <code>gcs</code> · <code>iam-service-account</code> |  |
| [stage-3.tf](./stage-3.tf) | None | <code>folder</code> · <code>gcs</code> · <code>iam-service-account</code> |  |
| [stage-cicd.tf](./stage-cicd.tf) | CI/CD locals and resources. | <code>iam-service-account</code> |  |
| [tenant-logging.tf](./tenant-logging.tf) | Audit log project and sink for tenant root folder. | <code>bigquery-dataset</code> · <code>gcs</code> · <code>logging-bucket</code> · <code>pubsub</code> |  |
| [tenant-root.tf](./tenant-root.tf) | None | <code>folder</code> · <code>project</code> |  |
| [top-level-folders.tf](./top-level-folders.tf) | None | <code>folder</code> · <code>gcs</code> · <code>iam-service-account</code> |  |
| [variables-addons.tf](./variables-addons.tf) | None |  |  |
| [variables-fast.tf](./variables-fast.tf) | FAST stage interface. |  |  |
| [variables-stages.tf](./variables-stages.tf) | None |  |  |
| [variables-toplevel-folders.tf](./variables-toplevel-folders.tf) | None |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [automation](variables-fast.tf#L19) | Automation resources created by the bootstrap stage. | <code title="object&#40;&#123;&#10;  outputs_bucket          &#61; string&#10;  project_id              &#61; string&#10;  project_number          &#61; string&#10;  federated_identity_pool &#61; string&#10;  federated_identity_providers &#61; map&#40;object&#40;&#123;&#10;    audiences        &#61; list&#40;string&#41;&#10;    issuer           &#61; string&#10;    issuer_uri       &#61; string&#10;    name             &#61; string&#10;    principal_branch &#61; string&#10;    principal_repo   &#61; string&#10;  &#125;&#41;&#41;&#10;  service_accounts &#61; object&#40;&#123;&#10;    resman   &#61; string&#10;    resman-r &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [billing_account](variables-fast.tf#L43) | Billing account id. If billing account is not part of the same org set `is_org_level` to `false`. To disable handling of billing IAM roles set `no_iam` to `true`. | <code title="object&#40;&#123;&#10;  id           &#61; string&#10;  is_org_level &#61; optional&#40;bool, true&#41;&#10;  no_iam       &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [environments](variables-fast.tf#L72) | Environment names. | <code title="map&#40;object&#40;&#123;&#10;  name       &#61; string&#10;  short_name &#61; string&#10;  tag_name   &#61; string&#10;  is_default &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  | <code>0-globals</code> |
| [logging](variables-fast.tf#L119) | Logging configuration for tenants. | <code title="object&#40;&#123;&#10;  project_id &#61; string&#10;  log_sinks &#61; optional&#40;map&#40;object&#40;&#123;&#10;    filter &#61; string&#10;    type   &#61; string&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>1-tenant-factory</code> |
| [organization](variables-fast.tf#L132) | Organization details. | <code title="object&#40;&#123;&#10;  domain      &#61; string&#10;  id          &#61; number&#10;  customer_id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [prefix](variables-fast.tf#L162) | Prefix used for resources that need unique names. Use 9 characters or less. | <code>string</code> | ✓ |  | <code>0-bootstrap</code> |
| [custom_roles](variables-fast.tf#L54) | Custom roles defined at the org level, in key => id format. | <code title="object&#40;&#123;&#10;  billing_viewer                  &#61; string&#10;  organization_admin_viewer       &#61; string&#10;  project_iam_viewer              &#61; string&#10;  service_project_network_admin   &#61; string&#10;  storage_viewer                  &#61; string&#10;  gcve_network_admin              &#61; optional&#40;string&#41;&#10;  gcve_network_viewer             &#61; optional&#40;string&#41;&#10;  network_firewall_policies_admin &#61; optional&#40;string&#41;&#10;  ngfw_enterprise_admin           &#61; optional&#40;string&#41;&#10;  ngfw_enterprise_viewer          &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> | <code>0-bootstrap</code> |
| [factories_config](variables.tf#L20) | Configuration for the resource factories or external data. | <code title="object&#40;&#123;&#10;  stage_2           &#61; optional&#40;string, &#34;data&#47;stage-2&#34;&#41;&#10;  stage_3           &#61; optional&#40;string, &#34;data&#47;stage-3&#34;&#41;&#10;  top_level_folders &#61; optional&#40;string, &#34;data&#47;top-level-folders&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [fast_addon](variables-addons.tf#L17) | FAST addons configurations for stages 2. Keys are used as short names for the add-on resources. | <code title="map&#40;object&#40;&#123;&#10;  parent_stage &#61; string&#10;  cicd_config &#61; optional&#40;object&#40;&#123;&#10;    identity_provider &#61; string&#10;    repository &#61; object&#40;&#123;&#10;      name   &#61; string&#10;      branch &#61; optional&#40;string&#41;&#10;      type   &#61; optional&#40;string, &#34;github&#34;&#41;&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [fast_stage_2](variables-stages.tf#L17) | FAST stages 2 configurations. | <code title="map&#40;object&#40;&#123;&#10;  short_name &#61; optional&#40;string&#41;&#10;  cicd_config &#61; optional&#40;object&#40;&#123;&#10;    identity_provider &#61; string&#10;    repository &#61; object&#40;&#123;&#10;      name   &#61; string&#10;      branch &#61; optional&#40;string&#41;&#10;      type   &#61; optional&#40;string, &#34;github&#34;&#41;&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;  folder_config &#61; optional&#40;object&#40;&#123;&#10;    name               &#61; string&#10;    parent_id          &#61; optional&#40;string&#41;&#10;    create_env_folders &#61; optional&#40;bool, true&#41;&#10;    iam                &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings       &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;      member &#61; string&#10;      role   &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    iam_by_principals &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    org_policies &#61; optional&#40;map&#40;object&#40;&#123;&#10;      inherit_from_parent &#61; optional&#40;bool&#41; &#35; for list policies only.&#10;      reset               &#61; optional&#40;bool&#41;&#10;      rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;        allow &#61; optional&#40;object&#40;&#123;&#10;          all    &#61; optional&#40;bool&#41;&#10;          values &#61; optional&#40;list&#40;string&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        deny &#61; optional&#40;object&#40;&#123;&#10;          all    &#61; optional&#40;bool&#41;&#10;          values &#61; optional&#40;list&#40;string&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        enforce &#61; optional&#40;bool&#41; &#35; for boolean policies only.&#10;        condition &#61; optional&#40;object&#40;&#123;&#10;          description &#61; optional&#40;string&#41;&#10;          expression  &#61; optional&#40;string&#41;&#10;          location    &#61; optional&#40;string&#41;&#10;          title       &#61; optional&#40;string&#41;&#10;        &#125;&#41;, &#123;&#125;&#41;&#10;      &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    tag_bindings &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;  organization_config &#61; optional&#40;object&#40;&#123;&#10;    iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;      member &#61; string&#10;      role   &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    iam_by_principals &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  stage3_config &#61; optional&#40;object&#40;&#123;&#10;    iam_admin_delegated &#61; optional&#40;list&#40;object&#40;&#123;&#10;      environment &#61; string&#10;      principal   &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    iam_viewer &#61; optional&#40;list&#40;object&#40;&#123;&#10;      environment &#61; string&#10;      principal   &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [fast_stage_3](variables-stages.tf#L114) | FAST stages 3 configurations. | <code title="map&#40;object&#40;&#123;&#10;  short_name  &#61; optional&#40;string&#41;&#10;  environment &#61; optional&#40;string, &#34;dev&#34;&#41;&#10;  cicd_config &#61; optional&#40;object&#40;&#123;&#10;    identity_provider &#61; string&#10;    repository &#61; object&#40;&#123;&#10;      name   &#61; string&#10;      branch &#61; optional&#40;string&#41;&#10;      type   &#61; optional&#40;string, &#34;github&#34;&#41;&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;  folder_config &#61; optional&#40;object&#40;&#123;&#10;    name         &#61; string&#10;    parent_id    &#61; optional&#40;string&#41;&#10;    tag_bindings &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    iam          &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;      member &#61; string&#10;      role   &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    iam_by_principals &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    org_policies &#61; optional&#40;map&#40;object&#40;&#123;&#10;      inherit_from_parent &#61; optional&#40;bool&#41; &#35; for list policies only.&#10;      reset               &#61; optional&#40;bool&#41;&#10;      rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;        allow &#61; optional&#40;object&#40;&#123;&#10;          all    &#61; optional&#40;bool&#41;&#10;          values &#61; optional&#40;list&#40;string&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        deny &#61; optional&#40;object&#40;&#123;&#10;          all    &#61; optional&#40;bool&#41;&#10;          values &#61; optional&#40;list&#40;string&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        enforce &#61; optional&#40;bool&#41; &#35; for boolean policies only.&#10;        condition &#61; optional&#40;object&#40;&#123;&#10;          description &#61; optional&#40;string&#41;&#10;          expression  &#61; optional&#40;string&#41;&#10;          location    &#61; optional&#40;string&#41;&#10;          title       &#61; optional&#40;string&#41;&#10;        &#125;&#41;, &#123;&#125;&#41;&#10;      &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [groups](variables-fast.tf#L90) | Group names or IAM-format principals to grant organization-level permissions. If just the name is provided, the 'group:' principal and organization domain are interpolated. | <code title="object&#40;&#123;&#10;  gcp-billing-admins      &#61; optional&#40;string, &#34;gcp-billing-admins&#34;&#41;&#10;  gcp-devops              &#61; optional&#40;string, &#34;gcp-devops&#34;&#41;&#10;  gcp-network-admins      &#61; optional&#40;string, &#34;gcp-vpc-network-admins&#34;&#41;&#10;  gcp-organization-admins &#61; optional&#40;string, &#34;gcp-organization-admins&#34;&#41;&#10;  gcp-secops-admins       &#61; optional&#40;string, &#34;gcp-secops-admins&#34;&#41;&#10;  gcp-security-admins     &#61; optional&#40;string, &#34;gcp-security-admins&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-bootstrap</code> |
| [locations](variables-fast.tf#L106) | Optional locations for GCS, BigQuery, and logging buckets created here. | <code title="object&#40;&#123;&#10;  bq      &#61; optional&#40;string, &#34;EU&#34;&#41;&#10;  gcs     &#61; optional&#40;string, &#34;EU&#34;&#41;&#10;  logging &#61; optional&#40;string, &#34;global&#34;&#41;&#10;  pubsub  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-bootstrap</code> |
| [org_policy_tags](variables-fast.tf#L150) | Organization policy tags. | <code title="object&#40;&#123;&#10;  key_id   &#61; optional&#40;string&#41;&#10;  key_name &#61; optional&#40;string, &#34;org-policies&#34;&#41;&#10;  values   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-bootstrap</code> |
| [outputs_location](variables.tf#L31) | Enable writing provider, tfvars and CI/CD workflow files to local filesystem. Leave null to disable. | <code>string</code> |  | <code>null</code> |  |
| [resource_names](variables.tf#L37) | Resource names overrides for specific resources. Stage names are interpolated via `$${name}`. Prefix is always set via code, except where noted in the variable type. | <code title="object&#40;&#123;&#10;  gcs-net      &#61; optional&#40;string, &#34;prod-resman-&#36;&#36;&#123;name&#125;-0&#34;&#41;&#10;  gcs-nsec     &#61; optional&#40;string, &#34;resman-&#36;&#36;&#123;name&#125;-0&#34;&#41;&#10;  gcs-pf       &#61; optional&#40;string, &#34;resman-&#36;&#36;&#123;name&#125;-0&#34;&#41;&#10;  gcs-sec      &#61; optional&#40;string, &#34;prod-resman-&#36;&#36;&#123;name&#125;-0&#34;&#41;&#10;  gcs-stage2   &#61; optional&#40;string, &#34;resman-&#36;&#36;&#123;name&#125;-0&#34;&#41;&#10;  gcs-stage3   &#61; optional&#40;string, &#34;resman-&#36;&#36;&#123;name&#125;-0&#34;&#41;&#10;  sa-cicd_ro   &#61; optional&#40;string, &#34;resman-&#36;&#36;&#123;name&#125;-1r&#34;&#41;&#10;  sa-cicd_rw   &#61; optional&#40;string, &#34;resman-&#36;&#36;&#123;name&#125;-1&#34;&#41;&#10;  sa-stage2_ro &#61; optional&#40;string, &#34;resman-&#36;&#36;&#123;name&#125;-0r&#34;&#41;&#10;  sa-stage2_rw &#61; optional&#40;string, &#34;resman-&#36;&#36;&#123;name&#125;-0&#34;&#41;&#10;  sa-stage3_ro &#61; optional&#40;string, &#34;resman-&#36;&#36;&#123;name&#125;-0r&#34;&#41;&#10;  sa-stage3_rw &#61; optional&#40;string, &#34;resman-&#36;&#36;&#123;name&#125;-0&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [root_node](variables-fast.tf#L168) | Root node for the hierarchy, if running in tenant mode. | <code>string</code> |  | <code>null</code> | <code>0-bootstrap</code> |
| [tag_names](variables.tf#L57) | Customized names for resource management tags. | <code title="object&#40;&#123;&#10;  context     &#61; optional&#40;string, &#34;context&#34;&#41;&#10;  environment &#61; optional&#40;string, &#34;environment&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [tags](variables.tf#L71) | Custom secure tags by key name. The `iam` attribute behaves like the similarly named one at module level. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;  iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  id          &#61; optional&#40;string&#41;&#10;  values &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;    iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    id          &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [top_level_folders](variables-toplevel-folders.tf#L17) | Additional top-level folders. Keys are used for service account and bucket names, values implement the folders module interface with the addition of the 'automation' attribute. | <code title="map&#40;object&#40;&#123;&#10;  name      &#61; string&#10;  parent_id &#61; optional&#40;string&#41;&#10;  automation &#61; optional&#40;object&#40;&#123;&#10;    environment_name            &#61; optional&#40;string, &#34;prod&#34;&#41;&#10;    sa_impersonation_principals &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    short_name                  &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  contacts &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  factories_config &#61; optional&#40;object&#40;&#123;&#10;    org_policies &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  firewall_policy &#61; optional&#40;object&#40;&#123;&#10;    name   &#61; string&#10;    policy &#61; string&#10;  &#125;&#41;&#41;&#10;  is_fast_context &#61; optional&#40;bool, true&#41;&#10;  logging_data_access &#61; optional&#40;map&#40;object&#40;&#123;&#10;    ADMIN_READ &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_READ  &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_WRITE &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  logging_exclusions &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  logging_settings &#61; optional&#40;object&#40;&#123;&#10;    disable_default_sink &#61; optional&#40;bool&#41;&#10;    storage_location     &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  logging_sinks &#61; optional&#40;map&#40;object&#40;&#123;&#10;    bq_partitioned_table &#61; optional&#40;bool, false&#41;&#10;    description          &#61; optional&#40;string&#41;&#10;    destination          &#61; string&#10;    disabled             &#61; optional&#40;bool, false&#41;&#10;    exclusions           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    filter               &#61; optional&#40;string&#41;&#10;    iam                  &#61; optional&#40;bool, true&#41;&#10;    include_children     &#61; optional&#40;bool, true&#41;&#10;    type                 &#61; string&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_by_principals &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  org_policies &#61; optional&#40;map&#40;object&#40;&#123;&#10;    inherit_from_parent &#61; optional&#40;bool&#41; &#35; for list policies only.&#10;    reset               &#61; optional&#40;bool&#41;&#10;    rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;      allow &#61; optional&#40;object&#40;&#123;&#10;        all    &#61; optional&#40;bool&#41;&#10;        values &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      deny &#61; optional&#40;object&#40;&#123;&#10;        all    &#61; optional&#40;bool&#41;&#10;        values &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      enforce &#61; optional&#40;bool&#41; &#35; for boolean policies only.&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        description &#61; optional&#40;string&#41;&#10;        expression  &#61; optional&#40;string&#41;&#10;        location    &#61; optional&#40;string&#41;&#10;        title       &#61; optional&#40;string&#41;&#10;      &#125;&#41;, &#123;&#125;&#41;&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  tag_bindings &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [cicd_repositories](outputs.tf#L65) | WIF configuration for CI/CD repositories. |  |  |
| [folder_ids](outputs.tf#L77) | Folder ids. |  |  |
| [providers](outputs.tf#L83) | Terraform provider files for this stage and dependent stages. | ✓ |  |
| [service_accounts](outputs.tf#L89) | Service accounts. |  |  |
| [tfvars](outputs.tf#L95) | Terraform variable files for the following stages. | ✓ |  |
<!-- END TFDOC -->
