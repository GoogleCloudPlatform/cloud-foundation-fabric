# Project Factory

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
- [How to run this stage](#how-to-run-this-stage)
  - [Bootstrap stage configuration](#bootstrap-stage-configuration)
    - [Automation resources](#automation-resources)
    - [Billing account](#billing-account)
    - [Organization IAM](#organization-iam)
    - [Parent folder](#parent-folder)
  - [Factory configuration](#factory-configuration)
  - [Stage provider and Terraform variables](#stage-provider-and-terraform-variables)
- [Managing folders and projects](#managing-folders-and-projects)
  - [Project defaults and overrides](#project-defaults-and-overrides)
  - [Folder and hierarchy management](#folder-and-hierarchy-management)
  - [Folder parent-child relationship and variable substitutions](#folder-parent-child-relationship-and-variable-substitutions)
  - [Project Creation](#project-creation)
  - [Automation Resources for Projects](#automation-resources-for-projects)
  - [Generated provider and Terraform variables for projects](#generated-provider-and-terraform-variables-for-projects)
    - [Individual output files](#individual-output-files)
    - [Pattern-defined output files](#pattern-defined-output-files)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

The Project Factory stage allows simplified management of folder hierarchies and projects via YAML-based configuration files. Multiple project factories can coexist in the same landing zone, and different patterns can be implemented by pointing them at different configuration files.

The pattern implemented here by default allows management of a teams (or business units, applications, etc.) hierarchy. Different patterns are possible, and this document also tries to provide some guidance on how to implement them.

## Design overview and choices

The project factory optionally "consumes" resources created by preceding stages, by using their outputs as a source for [context interpolation](../../../modules/project-factory/README.md#context-based-interpolation):

- folder ids from the bootstrap stage and via `var.context.folder_ids`
- project ids from the bootstrap and networking stages and via `var.context.project_ids`
- IAM principals from the bootstrap stage and via `var.context.iam_principals`
- tag values from the bootstrap stage and via `var.context.tag_values`
- KMS keys from the security stage and via `var.context.kms_keys`
- VPC SC perimeters from the VPC SC stage and via `var.context.vpc_sc_perimeters`

Additionally, some of the values defined earlier in the FAST apply cycle are set here as project defaults:

- prefix (as override)
- billing account
- storage location

The project factory stage is a thin wrapper of the underlying [project-factory module](../../../modules/project-factory/), which in turn exposes the full interface of the [project](../../../modules/project/) and [folder](../../../modules/folder/) modules.

## How to run this stage

This stage is meant to be executed after the [bootstrap](../0-org-setup/) stage. If any of the VPC SC, networking, and security stages have been applied, their resources can be directly leveraged via context interpolation as explained above.

### Bootstrap stage configuration

The bootstrap stage already contains the project factory automation resources, a sample "Teams" folder defined via YAML, and all the required IAM wiring to make this stage functional. The default "Teams" setup can be extended, or used as an example to implement different designs.

The bootstrap-specific setup is reproduced here to aid using it as a starting point. Only snippets relevant to this stage are shown below for simplicity.

#### Automation resources

The default design uses two service accounts (read-write and read-only) and a Cloud Storage folder in a pre-existing bucket, to enable this stage for Infrastructure as Code. This is an example snippet that shows how to configure the org setup stage IaC project.

```yaml
# data/projects/core/iac-0.yaml
buckets:
  iac-stage-state:
    description: Terraform state for stage automation.
    managed_folders:
      2-project-factory:
        iam:
          roles/storage.admin:
            - $iam_principals:service_accounts/iac-0/iac-pf-rw
          $custom_roles:storage_viewer:
            - $iam_principals:service_accounts/iac-0/iac-pf-ro
  iac-outputs:
    description: Terraform state for the org-level automation.
    iam:
      roles/storage.admin:
        - $iam_principals:service_accounts/iac-0/iac-pf-rw
      $custom_roles:storage_viewer:
        - $iam_principals:service_accounts/iac-0/iac-pf-ro
service_accounts:
  iac-pf-ro:
    display_name: IaC service account for project factory (read-only).
  iac-pf-rw:
    display_name: IaC service account for project factory (read-write).
```

#### Billing account

If an externally managed billing account is used, billing user permissions need to be assigned to the project factory service account.

```yaml
# data/billing-accounts/default.yaml
id: $defaults:billing_account
iam_bindings_additive:
  billing_user_pf_sa:
    role: roles/billing.user
    member: $iam_principals:service_accounts/iac-0/iac-pf-rw
```

#### Organization IAM

This stage only needs conditional grants for organization policy management at the organization level. Additionally, if an organization-managed billing account is used the IAM bindings described in the section above can be omitted, and moved to the organization.

```yaml
# data/organization/.config.yaml
iam_bindings:
  pf_org_policy_admin:
    role: roles/orgpolicy.policyAdmin
    members:
      - $iam_principals:service_accounts/iac-0/iac-pf-rw
    condition:
      expression: resource.matchTag('${organization}/context', 'project-factory')
      title: Project factory org policy admin
  pf_org_policy_viewer:
    role: roles/orgpolicy.policyViewer
    members:
      - $iam_principals:service_accounts/iac-0/iac-pf-ro
    condition:
      expression: resource.matchTag('${organization}/context', 'project-factory')
      title: Project factory org policy viewer
```

#### Parent folder

A single "Teams" folder is created here. Multiple folders (or sub-folders) can of course be created by replicating the IAM configuration below for each.

```yaml
# data/folders/teams/.config.yaml
name: Teams
iam_by_principals:
  $iam_principals:service_accounts/iac-0/iac-pf-rw:
    - roles/owner
    - roles/resourcemanager.folderAdmin
    - roles/resourcemanager.projectCreator
    - roles/resourcemanager.tagUser
    - $custom_roles:service_project_network_admin
  $iam_principals:service_accounts/iac-0/iac-pf-ro:
    - roles/viewer
    - roles/resourcemanager.folderViewer
    - roles/resourcemanager.tagViewer
tag_bindings:
  context: $tag_values:context/project-factory
```

### Factory configuration

The `data` folder in this stage contains factory files that can be used as examples to implement the team-based design shown above. Before running `terraform apply` check the YAML files, as project names and other attributes will need basic editing to match your desired setup.

### Stage provider and Terraform variables

As all other FAST stages, the [mechanism](../0-org-setup/README.md#output-files-and-cross-stage-variables) used to pass variable values and pre-built provider files from one stage to the next is also leveraged here.

The commands to link or copy the provider and terraform variable files can be easily derived from the `fast-links.sh` script in the FAST stages folder, passing it a single argument with the local output files folder (if configured) or the GCS output bucket in the automation project (derived from stage 0 outputs). The following examples demonstrate both cases, and the resulting commands that then need to be copy/pasted and run.

```bash
../fast-links.sh ~/fast-config

# File linking commands for project factory (org level) stage

# provider file
ln -s ~/fast-config/fast-test-00/providers/2-project-factory-providers.tf ./

# input files from other stages
ln -s ~/fast-config/fast-test-00/tfvars/0-globals.auto.tfvars.json ./
ln -s ~/fast-config/fast-test-00/tfvars/0-org-setup.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
ln -s ~/fast-config/fast-test-00/2-project-factory.auto.tfvars ./

# optional files
ln -s ~/fast-config/fast-test-00/2-networking.auto.tfvars.json ./
ln -s ~/fast-config/fast-test-00/2-security.auto.tfvars.json ./
ln -s ~/fast-config/fast-test-00/2-vpcsc.auto.tfvars.json ./
```

```bash
../fast-links.sh gs://xxx-prod-iac-core-outputs-0

# File linking commands for project factory (org level) stage

# provider file
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/providers/2-project-factory-providers.tf ./

# input files from other stages
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-org-setup.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/2-project-factory.auto.tfvars ./

# optional files
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/2-networking.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/2-security.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/2-vpcsc.auto.tfvars.json ./
```

If you're not using FAST, refer to the [Variables](#variables) table at the bottom of this document for a full list of variables, their origin (e.g., a stage or specific to this one), and descriptions explaining their meaning.

Besides the values above, the project factory is driven by YAML data files, with one file per project. Please refer to the underlying [project factory module](../../../modules/project-factory/) documentation for details on the format.

Once the configuration is complete, run the project factory with:

```bash
terraform init
terraform apply
```

## Managing folders and projects

The YAML data files are self-explanatory and the included [schema files](./schemas/) provide a reliable framework to allow editing the sample data, or starting from scratch to implement a different pattern. This section lists some general considerations on how folder and project files work to help getting up to speed with operations.

### Project defaults and overrides

The underlying module supports a way of defining sets of values that can be used as defaults of overrides for specific project attributes. This stage supports the same, and allows setting defaults and overrides either via Terraform variables, or via a dedicated YAML defaults file.

An example defaults file is provided in the `data` folder, and the relevant schema (or the corresponding variable type) supports the full interface provided in the underlying module. Defaults from Terraform variables and the YAML file are merged, with the caveat that Where the same attribute (for example `billing_account`) is defined in both, the file takes precedence.

### Folder and hierarchy management

The project factory manages its folder hierarchy via a filesystem tree, rooted in the path defined via the `factories_config.folders` variable.

Filesystem folders which contain a `.config.yaml` file are mapped to folders in the resource management hierarchy. Their YAML configuration files allow defining folder attributes like descriptive name, IAM bindings, organization policies, tag bindings.

This is the simple filesystem hierarchy provided here as an example.

```bash
hierarchy
├── team-a
│   ├── .config.yaml
│   ├── dev
│   │   └── .config.yaml
│   └── prod
│       └── .config.yaml
└── team-b
    ├── .config.yaml
    ├── dev
    │   └── .config.yaml
    └── prod
        └── .config.yaml
```

The approach is intentionally explicit and repetitive in order to simplify operations: copy/pasting an existing set of folders (or an ad hoc template) and changing a few YAML variables allows to quickly define new sub-hierarchy branches. Mass editing via search and replace functionality allows sweeping changes across the whole hierarchy.

Where inheritance is leveraged in the overall design config files can be deceptively simple: the following is the config file for the dev Team A folder in the provided example.

```yaml
name: Development
tag_bindings:
  environment: $tag_values:environment/development
iam_by_principals:
  "group:team-a-admins@example.com":
    - roles/editor
```

All of the [folder module](../../../modules/folder/) attributes can of course be leveraged in the configuration files. Refer to the [folder schema](./schemas/folder.schema.json) for the complete set of available attributes.

### Folder parent-child relationship and variable substitutions

In the example YAML configuration above there's no explicitly specified folder parent: it is derived from the filesystem hierarchy, and set to the "Team A" folder.

But what about the "Team A" folder itself? From the point of view of the project factory it's a top-level folder attached to the root of its hierarchy (the "Teams" folder), so how does it know where to create it in the GCP hierarchy?

There are two different ways to pass this information to the project factory:

- in the YAML file itself, by explicitly setting the folder's `parent` attribute to the explicit numeric id of the "Teams" folder (e.g. `folders/1234567890`)
- in the YAML file itself, by using explicit context interpolation (e.g. `$folder_ids:teams`)

This flexibility is what allows the project factory to manage folders under multiple roots, and to also be used for folders created outside of FAST. Imagine a scenario where there's no single "Teams" folder, but multiple ones for different subsidiaries, or for internal and external teams, etc.

The snippets below show how to set the `parent` attribute explicitly or via substitution in the YAML file.

```yaml
name: Team A
# use the explicit id of the Teams folder
parent: folders/1234567890
```

```yaml
name: Team A
# use context interpolation from stage 0 tfvars (preferred approach)
parent: $folder_ids:teams
```

### Project Creation

Project YAML files can be created in two different filesystem paths:

- in the filesystem folder defined via the `factories_config.projects` variable, and then explicitly setting their `parent` attribute in YAML files, or
- in the filesystem hierarchy discussed above, so that their `parent` attribute is automatically derived from the containing folder

The two approaches can be mixed and matched, but the first approach is safer as is avoids potentially dangerous situations when folders are deleted with project configuration files still inside.

When specifying projects outside of the folder hierarchy, setting the parent folder works in pretty much the same way as discussed above, with substitutions available for any folder defined in the filesystem hierarchy. This allows writing portable files, by referring to short names instead of resource ids.

```yaml
# use the explicit id of the parent folder
parent: folders/1234509876
```

```yaml
# use context interpolation from managed folders (preferred approach)
parent: $folder_ids:team-a/dev
```

All of the [project module](../../../modules/project/) attributes (and some service account attributes) can of course be leveraged in the configuration files. Refer to the [project schema](./schemas/folder.schema.json) for the complete set of available attributes.

### Automation Resources for Projects

When created projects are meant to be managed via IaC downstream, an initial set of automation resources can be created in a "controlling project". The preferred pattern is to first create one or more controlling projects for the project factory, and then leverage them for service account and GCS bucket creation.

```yaml
# controlling project shown in the diagram above
parent: $folder_ids:teams
name: $project_ids:iac-core-0
services:
  - compute.googleapis.com
  - storage.googleapis.com
  # ...
  # enable all services used by service accounts in this project
```

Once a controlling project is in place, it can be used in any other project declaration to host service accounts and bucket for automation. The service accounts can be used in IAM bindings in the same file by referring to their name via substitutions, as shown here.

```yaml
# file name: dev-ta-app-0.yaml (implicitly used for project id)
# team or application-level project with automation resources
parent: $folder_ids:team-a/dev
# project prefix is forced via override in `main.tf`
iam:
  roles/owner:
    # refer to the rw service account defined below
    - $iam_principals:service_accounts/dev-ta-app-0/rw
  roles/viewer:
    # refer to the ro service account defined below
    - $iam_principals:service_accounts/dev-ta-app-0/ro
automation:
  project: $project_ids:iac-core-0
  service_accounts:
    rw:
      description: Read/write automation sa for team a app 0.
    ro:
      description: Read-only automation sa for team a app 0.
  bucket:
    description: Terraform state bucket for team a app 0.
    iam:
      roles/storage.objectCreator:
        - $iam_principals:service_accounts/dev-ta-app-0/rw
      roles/storage.objectViewer:
        - $iam_principals:service_accounts/dev-ta-app-0/rw
        - $iam_principals:service_accounts/dev-ta-app-0/ro
        - group:devops@example.org
```

### Generated provider and Terraform variables for projects

This stage can optionally be configured to generate provider and tfvars files ("output files") for projects. These files can then be distributed to project owners to help them bootstrap automation, and will be used in future releases to configure project-level CI/CD from this factory.

Output file generation is configured in the defaults file, and supports two usage modes:

- individual output files can be generated for specific bucket/service account pairs, or
- a pattern can be defined to match automation service accounts defined in projects, and generate files for all projects that match the pattern

The first use case is simple to use for small setups, or where output files are needed to manage multiple projects from a single service account. The second use case allows mass generation of output files, where project automation service accounts conform to a specific template.

As is usual with FAST output files, their destination can be a storage bucket and/or a local filesystem folder. The two are not mutuallye exclusive and can be independently activated.

The following sub-sections illustrate the specifics of each of the two patterns described above.

#### Individual output files

To define individual output files, populate the `output_files.providers` map in this stage's defaults file. Each element in the map will result in one provider file, with a name matching the key used in the map.

```yaml
output_files:
  # where files are stored, either of these can be defined
  local_path: ~/fast-config/projects
  storage_bucket: $storage_buckets:iac-0/iac-shared-outputs
  # the template file used for providers, defaults to the built-in one
  # providers_template_path: assets/providers.tf.tpl
  providers:
    # a single explicit provider pointing to a specific bucket/service account
    test-01:
      storage_bucket: $storage_buckets:iac-0/iac-shared-state
      service_account: $iam_principals:service_accounts/prod-os-apt-0/automation/rw
      # the key is used as a backend prefix by default, use this to disable it
      # set_prefix: false
```

The above snippet will result in two identical files being generated:

- `~/fast-config/projects/providers/test-01.tf` in the local filesystem
- `projects/providers/test-01.tf` in the storage bucket

Individual files make specific assumptions:

- the service account and bucket can refer to any valid resource, either internally (via context) or externally (explicitly) defined
- where a backed prefix is set as in the example above, the assumption is the service account has permissions to use it
- no tfvars files are generated as the provider might be designed to work across different projects (this may change ina  future release)

#### Pattern-defined output files

To automatically generate output files for all projects matching a pattern, populate the `output_files.providers_pattern` block in this stage's defaults file. Note that the `local_path`, `storage_bucket` and `providers_template` attribute are the same as in the example above, and shared between individual and pattern providers definitions.

```yaml
output_files:
  # where files are stored, either of these can be defined
  local_path: ~/fast-config/projects
  storage_bucket: $storage_buckets:iac-0/iac-shared-outputs
  # the template file used for providers, defaults to the built-in one
  # providers_template_path: assets/providers.tf.tpl
  providers_pattern:
    # match automation service accounts in project definitions
    service_accounts_match:
      # at least one of the ro or rw matches needs to be defined
      ro: automation/ro
      rw: automation/rw
    # which bucket is used for the provider backend
    storage_bucket: $storage_buckets:iac-0/iac-shared-state
    # create managed folders in the bucket by default and set IAM on them
    # storage_folders_create: true
```

The above snippet will create zero, one, or two provider files depending on how many service accounts match for each individual project. One tfvars file will also be created for each project with at least one provider file.

For example, a project with this definition will generate one provider and one tfvars file for each of the top-level storage options (`output_files.local_path`, `output_files.storage_bucket`) defined.

```yaml
# file name: dev-foo-0.yaml
automation:
  project: $project_ids:iac-0
  service_accounts:
    rw:
      description: Read/write automation service account.
```

And one with this definition will generate two providers (one for each service account) and one tfvars file for each of the top-level storage options (`output_files.local_path`, `output_files.storage_bucket`) defined.

```yaml
# file name: dev-foo-0.yaml
automation:
  project: $project_ids:iac-0
  service_accounts:
    ro:
      description: Read-only automation service account.
    rw:
      description: Read/write automation service account.
```

Using the second example, these file names will be in the local filesystem (the bucket will have the same files save for the local path):

- `~/fast-config/projects/providers/dev-foo-0-ro.tf`
- `~/fast-config/projects/providers/dev-foo-0-rw.tf`
- `~/fast-config/projects/tfvars/dev-foo-0.tf`

Pattern-based files make specific assumptions:

- service accounts can only refer to project-factory generated service accounts in each project definition
- the backend prefix is always set, as the same bucket is used for all provider files

<!-- TFDOC OPTS files:1 show_extra:1 exclude:2-project-factory-providers.tf -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [main.tf](./main.tf) | Project factory. | <code>project-factory</code> |  |
| [output-files-storage.tf](./output-files-storage.tf) | None | <code>gcs</code> |  |
| [output-files.tf](./output-files.tf) | None |  | <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  | <code>google_storage_bucket_object</code> |
| [variables-fast.tf](./variables-fast.tf) | None |  |  |
| [variables-projects.tf](./variables-projects.tf) | None |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [automation](variables-fast.tf#L17) | Automation resources created by the bootstrap stage. | <code title="object&#40;&#123;&#10;  outputs_bucket &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-org-setup</code> |
| [billing_account](variables-fast.tf#L26) | Billing account id. | <code title="object&#40;&#123;&#10;  id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-org-setup</code> |
| [prefix](variables-fast.tf#L82) | Prefix used for resources that need unique names. Use a maximum of 9 chars for organizations, and 11 chars for tenants. | <code>string</code> | ✓ |  | <code>0-org-setup</code> |
| [context](variables.tf#L17) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  condition_vars        &#61; optional&#40;map&#40;map&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  custom_roles          &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  email_addresses       &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  folder_ids            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  kms_keys              &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations             &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  notification_channels &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_values            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  vpc_host_projects     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  vpc_sc_perimeters     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [custom_roles](variables-fast.tf#L34) | Custom roles defined at the org level, in key => id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [data_defaults](variables-projects.tf#L17) | Optional default values used when corresponding project or folder data from files are missing. | <code title="object&#40;&#123;&#10;  billing_account &#61; optional&#40;string&#41;&#10;  bucket &#61; optional&#40;object&#40;&#123;&#10;    force_destroy &#61; optional&#40;bool&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  contacts        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  deletion_policy &#61; optional&#40;string&#41;&#10;  factories_config &#61; optional&#40;object&#40;&#123;&#10;    custom_roles  &#61; optional&#40;string&#41;&#10;    observability &#61; optional&#40;string&#41;&#10;    org_policies  &#61; optional&#40;string&#41;&#10;    quotas        &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  labels &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations &#61; optional&#40;object&#40;&#123;&#10;    bigquery &#61; optional&#40;string&#41;&#10;    logging  &#61; optional&#40;string&#41;&#10;    storage  &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  logging_data_access &#61; optional&#40;map&#40;object&#40;&#123;&#10;    ADMIN_READ &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_READ  &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_WRITE &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  metric_scopes &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  parent        &#61; optional&#40;string&#41;&#10;  prefix        &#61; optional&#40;string&#41;&#10;  project_reuse &#61; optional&#40;object&#40;&#123;&#10;    use_data_source &#61; optional&#40;bool, true&#41;&#10;    attributes &#61; optional&#40;object&#40;&#123;&#10;      name             &#61; string&#10;      number           &#61; number&#10;      services_enabled &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  shared_vpc_service_config &#61; optional&#40;object&#40;&#123;&#10;    host_project &#61; string&#10;    iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;      member &#61; string&#10;      role   &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    network_users            &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    service_agent_iam        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_agent_subnet_iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_iam_grants       &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    network_subnet_users     &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;  tag_bindings &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  universe &#61; optional&#40;object&#40;&#123;&#10;    prefix                         &#61; string&#10;    forced_jit_service_identities  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    unavailable_service_identities &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    unavailable_services           &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;  vpc_sc &#61; optional&#40;object&#40;&#123;&#10;    perimeter_name &#61; string&#10;    is_dry_run     &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [data_merges](variables-projects.tf#L93) | Optional values that will be merged with corresponding data from files. Combines with `data_defaults`, file data, and `data_overrides`. | <code title="object&#40;&#123;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes              &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  tag_bindings               &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [data_overrides](variables-projects.tf#L112) | Optional values that override corresponding data from files. Takes precedence over file data and `data_defaults`. | <code title="object&#40;&#123;&#10;  billing_account &#61; optional&#40;string&#41;&#10;  bucket &#61; optional&#40;object&#40;&#123;&#10;    force_destroy &#61; optional&#40;bool&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  contacts        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  deletion_policy &#61; optional&#40;string&#41;&#10;  factories_config &#61; optional&#40;object&#40;&#123;&#10;    custom_roles  &#61; optional&#40;string&#41;&#10;    observability &#61; optional&#40;string&#41;&#10;    org_policies  &#61; optional&#40;string&#41;&#10;    quotas        &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  locations &#61; optional&#40;object&#40;&#123;&#10;    bigquery &#61; optional&#40;string&#41;&#10;    logging  &#61; optional&#40;string&#41;&#10;    storage  &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  logging_data_access &#61; optional&#40;map&#40;object&#40;&#123;&#10;    ADMIN_READ &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_READ  &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_WRITE &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  parent &#61; optional&#40;string&#41;&#10;  prefix &#61; optional&#40;string&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  tag_bindings               &#61; optional&#40;map&#40;string&#41;&#41;&#10;  universe &#61; optional&#40;object&#40;&#123;&#10;    prefix                         &#61; string&#10;    forced_jit_service_identities  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    unavailable_service_identities &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    unavailable_services           &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;  vpc_sc &#61; optional&#40;object&#40;&#123;&#10;    perimeter_name &#61; string&#10;    is_dry_run     &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [factories_config](variables.tf#L37) | Path to folder with YAML resource description data files. | <code title="object&#40;&#123;&#10;  defaults &#61; optional&#40;string, &#34;data&#47;defaults.yaml&#34;&#41;&#10;  folders  &#61; optional&#40;string, &#34;data&#47;folders&#34;&#41;&#10;  projects &#61; optional&#40;string, &#34;data&#47;projects&#34;&#41;&#10;  budgets &#61; optional&#40;object&#40;&#123;&#10;    billing_account_id &#61; string&#10;    data               &#61; string&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [folder_ids](variables-fast.tf#L42) | Folders created in the bootstrap stage. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [host_project_ids](variables-fast.tf#L58) | Host project for the shared VPC. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
| [iam_principals](variables-fast.tf#L50) | IAM-format principals. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [kms_keys](variables-fast.tf#L66) | KMS key ids. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-security</code> |
| [perimeters](variables-fast.tf#L74) | Optional VPC-SC perimeter ids. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>1-vpcsc</code> |
| [project_ids](variables-fast.tf#L92) | Projects created in the bootstrap stage. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [security_project_ids](variables-fast.tf#L100) | Projects created in the security stage. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-security</code> |
| [service_accounts](variables-fast.tf#L108) | Service accounts created in the bootstrap stage. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [stage_name](variables.tf#L58) | FAST stage name. Used to separate output files across different factories. | <code>string</code> |  | <code>&#34;2-project-factory&#34;</code> |  |
| [subnet_self_links](variables-fast.tf#L116) | Shared VPC subnet IDs. | <code>map&#40;map&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
| [tag_values](variables-fast.tf#L124) | FAST-managed resource manager tag values. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [universe](variables-fast.tf#L132) | GCP universe where to deploy projects. The prefix will be prepended to the project id. | <code title="object&#40;&#123;&#10;  domain                         &#61; string&#10;  prefix                         &#61; string&#10;  forced_jit_service_identities  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  unavailable_services           &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  unavailable_service_identities &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> | <code>0-org-setup</code> |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [projects](outputs.tf#L17) | Attributes for managed projects. |  |  |
<!-- END TFDOC -->
