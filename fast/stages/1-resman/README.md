# Resource hierarchy

This stage performs two important tasks:

- create the top-level hierarchy of folders, and the associated resources used later on to automate each part of the hierarchy (eg. Networking)
- set organization policies on the organization, and any exception required on specific folders

The code is intentionally simple, as it's intended to provide a generic initial setup (Networking, Security, etc.), and then allow easy customizations to complete the implementation of the intended hierarchy design.

The following diagram is a high level reference of the resources created and managed here:

<p align="center">
  <img src="diagram.svg" alt="Resource-management diagram">
</p>

## Table of contents

- [Design overview and choices](#design-overview-and-choices)
  - [Multitenancy](#multitenancy)
  - [Workload Identity Federation and CI/CD](#workload-identity-federation-and-cicd)
- [How to run this stage](#how-to-run-this-stage)
  - [Provider and Terraform variables](#provider-and-terraform-variables)
  - [Impersonating the automation service account](#impersonating-the-automation-service-account)
  - [Variable configuration](#variable-configuration)
  - [Running the stage](#running-the-stage)
- [Customizations](#customizations)
  - [Secure tags](#secure-tags)
  - [Lightweight multitenancy](#lightweight-multitenancy)
  - [Team folders](#team-folders)
  - [Organization Policies](#organization-policies)
  - [IAM](#iam)
  - [Additional folders](#additional-folders)

## Design overview and choices

Despite its simplicity, this stage implements the basics of a design that we've seen working well for a variety of customers, where the hierarchy is laid out following two conceptually different approaches:

- core or shared resources are grouped in hierarchy branches that map to their type or purpose (e.g. Networking)
- team or application resources are grouped in lower level hierarchy branches that map to management or operational considerations (e.g. which team manages a set of applications, or owns a subset of company data, etc.)

This split approach usually represents well functional and operational patterns, where core resources are centrally managed by individual teams (e.g. networking, security, fleets of similar VMS, etc.), while teams need more granularity to access managed services used by the applications they maintain.

The approach also adapts to different high level requirements:

- it can be used either for single organizations containing multiple environments, or with multiple organizations dedicated to specific environments (e.g. prod/nonprod), as the environment split is implemented at the project or lower folder level
- it adapts to complex scenarios, with different countries or corporate entities using the same GCP organization, as core services are typically shared, and/or an extra layer on top can be used as a drop-in to implement the country/entity separation

Additionally, a few critical benefits are directly provided by this design:

- core services are clearly separated, with very few touchpoints where IAM and security policies need to be applied (typically their top-level folder)
- adding a new set of core services (e.g. shared GKE clusters) is a trivial operation that does not break the existing design
- grouping application resources and services using teams or business logic is a flexible approach, which maps well to typical operational or budget requirements
- automation stages (e.g. Networking) can be segregated in a simple and effective way, by creating the required service accounts and buckets for each stage here, and applying a handful of IAM roles to the relevant folder

For a discussion on naming, please refer to the [Bootstrap stage documentation](../0-bootstrap/README.md#naming), as the same approach is shared by all stages.

### Multitenancy

Fully multitenant hierarchies inside the same organization are implemented via [separate additional stages](../../stages-multitenant/) that need to be run once for each tenant, and require this stage as a prerequisite.

### Workload Identity Federation and CI/CD

This stage also implements optional support for CI/CD, much in the same way as the bootstrap stage. The only difference is on Workload Identity Federation, which is only configured in bootstrap and made available here via stage interface variables (the automatically generated `.tfvars` files).

For details on how to configure CI/CD please refer to the [relevant section in the bootstrap stage documentation](../0-bootstrap/README.md#cicd-repositories).

## How to run this stage

This stage is meant to be executed after the [bootstrap](../0-bootstrap) stage has run, as it leverages the automation service account and bucket created there. The relevant user groups must also exist, but that's one of the requirements for the previous stage too, so if you ran that successfully, you're good to go.

It's of course possible to run this stage in isolation, but that's outside the scope of this document, and you would need to refer to the code for the bootstrap stage for the actual roles needed.

Before running this stage, you need to make sure you have the correct credentials and permissions, and localize variables by assigning values that match your configuration.

### Provider and Terraform variables

As all other FAST stages, the [mechanism used to pass variable values and pre-built provider files from one stage to the next](../0-bootstrap/README.md#output-files-and-cross-stage-variables) is also leveraged here.

The commands to link or copy the provider and terraform variable files can be easily derived from the `stage-links.sh` script in the FAST root folder, passing it a single argument with the local output files folder (if configured) or the GCS output bucket in the automation project (derived from stage 0 outputs). The following examples demonstrate both cases, and the resulting commands that then need to be copy/pasted and run.

```bash
../../stage-links.sh ~/fast-config

# copy and paste the following commands for '1-resman'

ln -s ~/fast-config/providers/1-resman-providers.tf ./
ln -s ~/fast-config/tfvars/0-globals.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/0-bootstrap.auto.tfvars.json ./
```

```bash
../../stage-links.sh gs://xxx-prod-iac-core-outputs-0

# copy and paste the following commands for '1-resman'

gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/providers/1-resman-providers.tf ./
gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./
```

### Impersonating the automation service account

The preconfigured provider file uses impersonation to run with this stage's automation service account's credentials. The `gcp-devops` and `organization-admins` groups have the necessary IAM bindings in place to do that, so make sure the current user is a member of one of those groups.

### Variable configuration

Variables in this stage -- like most other FAST stages -- are broadly divided into three separate sets:

- variables which refer to global values for the whole organization (org id, billing account id, prefix, etc.), which are pre-populated via the `0-globals.auto.tfvars.json` file linked or copied above
- variables which refer to resources managed by previous stage, which are prepopulated here via the `0-bootstrap.auto.tfvars.json` file linked or copied above
- and finally variables that optionally control this stage's behaviour and customizations, and can to be set in a custom `terraform.tfvars` file

The latter set is explained in the [Customization](#customizations) sections below, and the full list can be found in the [Variables](#variables) table at the bottom of this document.

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

## Customizations

### Secure tags

This stage manages [Secure Tags](https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing) at the organization level, via two sets of keys and values:

- a default set of tags used by FAST itself in specific IAM conditions that allow automation service accounts to gain organization-level privileges or specific access to parts of the resource management hierarchy
- an optional set of user-defined tags that can be used in organization policy or IAM conditions

The first set of default tags cannot be overridden and defines the following keys and values (key names can be changed via the `tag_names` variable):

- `context` to identify parts of the resource hierarchy, with `data`, `gke`, `networking`, `sandbox`, `security` and `teams` values
- `environment` to identify folders and projects belonging to specific environments, with `development` and `production` values
- `tenant` for FAST multitenant, with one value for each defined tenant that identifies their specific set of resources

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

### Lightweight multitenancy

If the organization needs to support tenants without the full complexity and separation offered by our [full multitenant support](../../stages-multitenant/), this stage offers a simplified setup which is suitable for cases where tenants have less autonomy, and don't need to implement FAST stages inside their reserved partition.

This mode is activated by defining tenants in the `tenants` variable, while IAM configurations that apply to every tenant can be optionally set in the `tenants_config` variable.

The resulting setup provides a new "Tenants" branch in the hierarchy with one second-level folder for each tenant, and additional folders inside it to host tenant resources managed from the central team, and tenant resources managed by the tenant itself. Automation resources are provided for both teams.

This allows subsequent Terraform stages to create network resources for each tenant which are centrally managed and connected to central networking, and tenants themselves to optionally manage their own networking and application projects.

The default roles applied on tenant folders are

- on the top-level folder for each tenant
  - for the core IaC service account
    - `roles/cloudasset.owner`
    - `roles/compute.xpnAdmin`
    - `roles/logging.admin`
    - `roles/resourcemanager.folderAdmin`
    - `roles/resourcemanager.projectCreator`
    - `roles/resourcemanager.tagUser`
- on the core folder for each tenant
  - for the core IaC service account
    - `roles/owner`
  - for the tenant admin group and IaC service account
    - `roles/viewer`
- on the tenant folder for each tenant
  - for the tenant admin group and IaC service account
    - `roles/cloudasset.owner`
    - `roles/compute.xpnAdmin`
    - `roles/logging.admin`
    - `roles/resourcemanager.folderAdmin`
    - `roles/resourcemanager.projectCreator`
    - `roles/resourcemanager.tagUser`
    - `roles/owner`
  
Further customization is possible via the `tenants_config` variable.

This is a high level diagram of the design described above.

```mermaid
%%{init: {'theme':'base'}}%%
classDiagram
    Organization -- Tenants_root~📁~
    Organization -- org_iac
    Tenants_root~📁~ -- Tenant_0_root~📁~
    Tenants_root~📁~ -- Tenant_1_root~📁~
    Tenant_0_root~📁~ -- Tenant_0_core~📁~
    Tenant_0_root~📁~ -- Tenant_0_self~📁~
    Tenant_0_self~📁~ -- tenant0_iac
    Tenant_1_root~📁~ -- Tenant_1_core~📁~
    Tenant_1_root~📁~ -- Tenant_1_self~📁~
    Tenant_1_self~📁~ -- tenant1_iac
    class org_iac["org_iac (from stage 0)"] {
        - GCS buckets
        - service accounts
    }
    class Tenants_root~📁~ {
        - IAM bindings()
    }
    class Tenant_0_root~📁~ {
        - IAM bindings()
    }
    class Tenant_0_core~📁~ {
        - IAM bindings()
    }
    class Tenant_0_self~📁~ {
        - IAM bindings()
    }
    class tenant0_iac {
        - GCS buckets
        - service account
        - IAM bindings()
    }
    class Tenant_1_root~📁~ {
        - IAM bindings()
    }
    class Tenant_1_core~📁~ {
        - IAM bindings()
    }
    class Tenant_1_self~📁~ {
        - IAM bindings()
    }
    class tenant1_iac {
        - GCS buckets
        - service account
        - IAM bindings()
    }
```

This is an example that shows how to populate the relevant variables.

```tfvars
tenants = {
  tn0 = {
    admin_principal   = "group:tn-0-admins@tenant.example.org"
    descriptive_name  = "Tenant 0"
    # an optional billing account and org can be specified for the tenant
    organization = {
      customer_id = "CAbCde0123"
      domain      = "tenant.example.com"
      id          = 1234567890
    }
  }
  tnq = {
    admin_principal   = "group:tn-1-admins@example.org"
    descriptive_name  = "Tenant 1"
  }
}
tenants_config = {
  core_folder_roles = [
    "roles/compute.instanceAdmin.v1",
    "organizations/1234567890/roles/tenantLoadBalancerAdmin"
  ]
  top_folder_roles = ["roles/logging.admin", "roles/monitoring.admin"]
}
```

Providers and tfvars files will be created for each tenant.

### Team folders

This stage provides a single built-in customization that offers a minimal (but usable) implementation of the "application" or "business" grouping for resources discussed above. The `team_folders` variable allows you to specify a map of team name and groups, that will result in folders, automation service accounts, and IAM policies applied.

Consider the following example in a `tfvars` file:

```tfvars
team_folders = {
  team-a = {
    descriptive_name = "Team A"
    iam_by_principals = {
      "group:team-a@gcp-pso-italy.net" = [
        "roles/viewer"
      ]
    }
    impersonation_principals = ["group:team-a-admins@gcp-pso-italy.net"]
  }
}
```

This will result in

- a "Team A" folder under the "Teams" folder
- one GCS bucket in the automation project
- one service account in the automation project with the correct IAM policies on the folder and bucket
- a IAM policy on the folder that assigns `roles/viewer` to the `team-a` group
- a IAM policy on the service account that allows `team-a` to impersonate it

This allows to centralize the minimum set of resources to delegate control of each team's folder to a pipeline, and/or to the team group. This can be used as a starting point for scenarios that implement more complex requirements (e.g. environment folders per team, etc.).

### IAM

The `folder_iam` variable can be used to manage authoritative bindings for all top-level folders. For additional control, IAM roles can be easily edited in the relevant `branch-xxx.tf` file, following the best practice outlined in the [bootstrap stage](../0-bootstrap#customizations) documentation of separating user-level and service-account level IAM policies throuth the IAM-related variables (`iam`, `iam_bindings`, `iam_bindings_additive`) of the relevant modules.

A full reference of IAM roles managed by this stage [is available here](./IAM.md).

### Additional folders

Due to its simplicity, this stage lends itself easily to customizations: adding a new top-level branch (e.g. for shared GKE clusters) is as easy as cloning one of the `branch-xxx.tf` files, and changing names.

<!-- TFDOC OPTS files:1 show_extra:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [billing.tf](./billing.tf) | Billing resources for external billing use cases. |  | <code>google_billing_account_iam_member</code> |
| [branch-data-platform.tf](./branch-data-platform.tf) | Data Platform stages resources. | <code>folder</code> · <code>gcs</code> · <code>iam-service-account</code> |  |
| [branch-gcve.tf](./branch-gcve.tf) | GCVE stage resources. | <code>folder</code> · <code>gcs</code> · <code>iam-service-account</code> |  |
| [branch-gke.tf](./branch-gke.tf) | GKE multitenant stage resources. | <code>folder</code> · <code>gcs</code> · <code>iam-service-account</code> |  |
| [branch-networking.tf](./branch-networking.tf) | Networking stage resources. | <code>folder</code> · <code>gcs</code> · <code>iam-service-account</code> |  |
| [branch-project-factory.tf](./branch-project-factory.tf) | Project factory stage resources. | <code>gcs</code> · <code>iam-service-account</code> |  |
| [branch-sandbox.tf](./branch-sandbox.tf) | Sandbox stage resources. | <code>folder</code> · <code>gcs</code> · <code>iam-service-account</code> |  |
| [branch-security.tf](./branch-security.tf) | Security stage resources. | <code>folder</code> · <code>gcs</code> · <code>iam-service-account</code> |  |
| [branch-teams.tf](./branch-teams.tf) | Team stage resources. | <code>folder</code> · <code>gcs</code> · <code>iam-service-account</code> |  |
| [branch-tenants.tf](./branch-tenants.tf) | Lightweight tenant resources. | <code>folder</code> · <code>gcs</code> · <code>iam-service-account</code> · <code>project</code> |  |
| [checklist.tf](./checklist.tf) | None | <code>folder</code> |  |
| [cicd-data-platform.tf](./cicd-data-platform.tf) | CI/CD resources for the data platform branch. | <code>iam-service-account</code> · <code>source-repository</code> |  |
| [cicd-gcve.tf](./cicd-gcve.tf) | CI/CD resources for the GCVE branch. | <code>iam-service-account</code> · <code>source-repository</code> |  |
| [cicd-gke.tf](./cicd-gke.tf) | CI/CD resources for the GKE multitenant branch. | <code>iam-service-account</code> · <code>source-repository</code> |  |
| [cicd-networking.tf](./cicd-networking.tf) | CI/CD resources for the networking branch. | <code>iam-service-account</code> · <code>source-repository</code> |  |
| [cicd-project-factory.tf](./cicd-project-factory.tf) | CI/CD resources for the teams branch. | <code>iam-service-account</code> · <code>source-repository</code> |  |
| [cicd-security.tf](./cicd-security.tf) | CI/CD resources for the security branch. | <code>iam-service-account</code> · <code>source-repository</code> |  |
| [cicd-teams.tf](./cicd-teams.tf) | CI/CD resources for individual teams. | <code>iam-service-account</code> · <code>source-repository</code> |  |
| [main.tf](./main.tf) | Module-level locals and resources. |  |  |
| [organization-iam.tf](./organization-iam.tf) | Organization-level IAM bindings locals. |  |  |
| [organization.tf](./organization.tf) | Organization policies. | <code>organization</code> |  |
| [outputs-files.tf](./outputs-files.tf) | Output files persistence to local filesystem. |  | <code>local_file</code> |
| [outputs-gcs.tf](./outputs-gcs.tf) | Output files persistence to automation GCS bucket. |  | <code>google_storage_bucket_object</code> |
| [outputs-tenants.tf](./outputs-tenants.tf) | None |  | <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [automation](variables.tf#L20) | Automation resources created by the bootstrap stage. | <code title="object&#40;&#123;&#10;  outputs_bucket          &#61; string&#10;  project_id              &#61; string&#10;  project_number          &#61; string&#10;  federated_identity_pool &#61; string&#10;  federated_identity_providers &#61; map&#40;object&#40;&#123;&#10;    audiences        &#61; list&#40;string&#41;&#10;    issuer           &#61; string&#10;    issuer_uri       &#61; string&#10;    name             &#61; string&#10;    principal_branch &#61; string&#10;    principal_repo   &#61; string&#10;  &#125;&#41;&#41;&#10;  service_accounts &#61; object&#40;&#123;&#10;    resman-r &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [billing_account](variables.tf#L42) | Billing account id. If billing account is not part of the same org set `is_org_level` to `false`. To disable handling of billing IAM roles set `no_iam` to `true`. | <code title="object&#40;&#123;&#10;  id           &#61; string&#10;  is_org_level &#61; optional&#40;bool, true&#41;&#10;  no_iam       &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [organization](variables.tf#L232) | Organization details. | <code title="object&#40;&#123;&#10;  domain      &#61; string&#10;  id          &#61; number&#10;  customer_id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [prefix](variables.tf#L248) | Prefix used for resources that need unique names. Use 9 characters or less. | <code>string</code> | ✓ |  | <code>0-bootstrap</code> |
| [cicd_repositories](variables.tf#L53) | CI/CD repository configuration. Identity providers reference keys in the `automation.federated_identity_providers` variable. Set to null to disable, or set individual repositories to null if not needed. | <code title="object&#40;&#123;&#10;  data_platform_dev &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  data_platform_prod &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  gke_dev &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  gke_prod &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  gcve_dev &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  gcve_prod &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  networking &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  project_factory_dev &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  project_factory_prod &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  security &#61; optional&#40;object&#40;&#123;&#10;    name              &#61; string&#10;    type              &#61; string&#10;    branch            &#61; optional&#40;string&#41;&#10;    identity_provider &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |  |
| [custom_roles](variables.tf#L147) | Custom roles defined at the org level, in key => id format. | <code title="object&#40;&#123;&#10;  gcve_network_admin            &#61; string&#10;  organization_admin_viewer     &#61; string&#10;  service_project_network_admin &#61; string&#10;  storage_viewer                &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> | <code>0-bootstrap</code> |
| [factories_config](variables.tf#L159) | Configuration for the resource factories or external data. | <code title="object&#40;&#123;&#10;  checklist_data &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [fast_features](variables.tf#L168) | Selective control for top-level FAST features. | <code title="object&#40;&#123;&#10;  data_platform   &#61; optional&#40;bool, false&#41;&#10;  gke             &#61; optional&#40;bool, false&#41;&#10;  gcve            &#61; optional&#40;bool, false&#41;&#10;  project_factory &#61; optional&#40;bool, false&#41;&#10;  sandbox         &#61; optional&#40;bool, false&#41;&#10;  teams           &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-0-bootstrap</code> |
| [folder_iam](variables.tf#L183) | Authoritative IAM for top-level folders. | <code title="object&#40;&#123;&#10;  data_platform &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  gcve          &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  gke           &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  sandbox       &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  security      &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  network       &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  teams         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  tenants       &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [groups](variables.tf#L199) | Group names or IAM-format principals to grant organization-level permissions. If just the name is provided, the 'group:' principal and organization domain are interpolated. | <code title="object&#40;&#123;&#10;  gcp-billing-admins      &#61; optional&#40;string, &#34;gcp-billing-admins&#34;&#41;&#10;  gcp-devops              &#61; optional&#40;string, &#34;gcp-devops&#34;&#41;&#10;  gcp-network-admins      &#61; optional&#40;string, &#34;gcp-network-admins&#34;&#41;&#10;  gcp-organization-admins &#61; optional&#40;string, &#34;gcp-organization-admins&#34;&#41;&#10;  gcp-security-admins     &#61; optional&#40;string, &#34;gcp-security-admins&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-bootstrap</code> |
| [locations](variables.tf#L214) | Optional locations for GCS, BigQuery, and logging buckets created here. | <code title="object&#40;&#123;&#10;  bq      &#61; string&#10;  gcs     &#61; string&#10;  logging &#61; string&#10;  pubsub  &#61; list&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  bq      &#61; &#34;EU&#34;&#10;  gcs     &#61; &#34;EU&#34;&#10;  logging &#61; &#34;global&#34;&#10;  pubsub  &#61; &#91;&#93;&#10;&#125;">&#123;&#8230;&#125;</code> | <code>0-bootstrap</code> |
| [outputs_location](variables.tf#L242) | Enable writing provider, tfvars and CI/CD workflow files to local filesystem. Leave null to disable. | <code>string</code> |  | <code>null</code> |  |
| [tag_names](variables.tf#L259) | Customized names for resource management tags. | <code title="object&#40;&#123;&#10;  context     &#61; optional&#40;string, &#34;context&#34;&#41;&#10;  environment &#61; optional&#40;string, &#34;environment&#34;&#41;&#10;  tenant      &#61; optional&#40;string, &#34;tenant&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [tags](variables.tf#L274) | Custom secure tags by key name. The `iam` attribute behaves like the similarly named one at module level. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;  iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  values &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;    iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    id          &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [team_folders](variables.tf#L295) | Team folders to be created. Format is described in a code comment. | <code title="map&#40;object&#40;&#123;&#10;  descriptive_name         &#61; string&#10;  iam_by_principals        &#61; map&#40;list&#40;string&#41;&#41;&#10;  impersonation_principals &#61; list&#40;string&#41;&#10;  cicd &#61; optional&#40;object&#40;&#123;&#10;    branch            &#61; string&#10;    identity_provider &#61; string&#10;    name              &#61; string&#10;    type              &#61; string&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |  |
| [tenants](variables.tf#L311) | Lightweight tenant definitions. | <code title="map&#40;object&#40;&#123;&#10;  admin_principal  &#61; string&#10;  descriptive_name &#61; string&#10;  billing_account  &#61; optional&#40;string&#41;&#10;  organization &#61; optional&#40;object&#40;&#123;&#10;    customer_id &#61; string&#10;    domain      &#61; string&#10;    id          &#61; number&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [tenants_config](variables.tf#L327) | Lightweight tenants shared configuration. Roles will be assigned to tenant admin group and service accounts. | <code title="object&#40;&#123;&#10;  core_folder_roles   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  tenant_folder_roles &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  top_folder_roles    &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [cicd_repositories](outputs.tf#L391) | WIF configuration for CI/CD repositories. |  |  |
| [dataplatform](outputs.tf#L405) | Data for the Data Platform stage. |  |  |
| [gcve](outputs.tf#L421) | Data for the GCVE stage. |  | <code>03-gke-multitenant</code> |
| [gke_multitenant](outputs.tf#L442) | Data for the GKE multitenant stage. |  | <code>03-gke-multitenant</code> |
| [networking](outputs.tf#L463) | Data for the networking stage. |  |  |
| [project_factories](outputs.tf#L472) | Data for the project factories stage. |  |  |
| [providers](outputs.tf#L487) | Terraform provider files for this stage and dependent stages. | ✓ | <code>02-networking</code> · <code>02-security</code> · <code>03-dataplatform</code> · <code>xx-sandbox</code> · <code>xx-teams</code> |
| [sandbox](outputs.tf#L494) | Data for the sandbox stage. |  | <code>xx-sandbox</code> |
| [security](outputs.tf#L508) | Data for the networking stage. |  | <code>02-security</code> |
| [team_cicd_repositories](outputs.tf#L518) | WIF configuration for Team CI/CD repositories. |  |  |
| [teams](outputs.tf#L532) | Data for the teams stage. |  |  |
| [tfvars](outputs.tf#L544) | Terraform variable files for the following stages. | ✓ |  |
<!-- END TFDOC -->
