# VPC Service Controls

This stage sets up VPC Service Controls (VPC-SC) for the whole organization and is a thing FAST-compliant wrapper on the [VPC-SC module](../../../modules/vpc-sc/), with some minimal defaults.

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
  - [Single perimeter with built-in extensibility](#single-perimeter-with-built-in-extensibility)
  - [Factories for VPC-SC configuration](#factories-for-vpc-sc-configuration)
  - [Default geo-based access level](#default-geo-based-access-level)
  - [Ingress policy for organization-level log sinks](#ingress-policy-for-organization-level-log-sinks)
  - [Perimeter membership](#perimeter-membership)
    - [Resource discovery](#resource-discovery)
    - [Manual resource membership](#manual-resource-membership)
  - [Enforced vs dry-run perimeters](#enforced-vs-dry-run-perimeters)
- [Context expansion](#context-expansion)
  - [Static contexts](#static-contexts)
  - [Stage-generated contexts](#stage-generated-contexts)
- [How to run this stage](#how-to-run-this-stage)
  - [Provider and Terraform variables](#provider-and-terraform-variables)
  - [Impersonating the automation service account](#impersonating-the-automation-service-account)
  - [Variable configuration](#variable-configuration)
  - [Running the stage](#running-the-stage)
- [Customizations](#customizations)
  - [Access policy](#access-policy)
  - [Perimeters](#perimeters)
  - [Access levels](#access-levels)
  - [Ingress/egress policies](#ingressegress-policies)
- [Notes](#notes)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Design overview and choices

The approach to VPC-SC design implemented in this stage aims at providing the simplest possible configuration that can be set to enforced mode, so as to provide immediate protection while minimizing operational complexity (which can be very high for VPC-SC).

### Single perimeter with built-in extensibility

This stage uses a single VPC-SC perimeter by default, which is enough to provide protection against data exfiltration and use of credentials from outside of established boundaries, while minimizing operational toil.

The perimeter is set to dry-run mode by default, but the suggestion is to switch to enforced mode immediately after defining the initial set of access level and ingress/egress policies. This prevents the common situation where a complex design is deployed in dry-run mode, and then never enforced as the burden of addressing all violations is too high. A simpler design like the one presented here that employs very coarse access levels can be enforced quickly, and then refined iteratively as operations are streamlined and familiarity with VPC-SC quirks increases.

The stage is designed to allow defining additional perimeters via the `perimeters` variable, with a few caveats:

- there's no support for perimeter bridges, if those are needed they need to be integrated via code (which is easy enough to do anyway)
- only one set of discovered resources is supported and made available via the `$resource_sets:discovered_projects` context expansion
- the factory files for access levels and ingress/egress policies use the same folder regardless of perimeter, but their inclusion in a perimeter is controlled by the perimeter-level `access_levels`, `ingress_policies`, and `egress_policies` attributes.

### Factories for VPC-SC configuration

Restricted services, access levels, ingress and egress policies and perimeters can all be configured via YAML-based files, which allow intuitive editing and minimize the complexity of running operations.

The default setup only contains a single access level and an initial list of restricted services in the `datasets/classic/access-levels` folder and the `datasets/classic/restricted-services.yaml` file.

To configure ingress and egress policies simply add `ingress_policies` and/or `egress_policies` folders under `data`, or point the factories to your own folders by changing the `factories_config` variable values. For more details on how the `factories_config` interface works, refer to the [documentation for stage 0](../0-org-setup/README.md#selectconfigure-a-factory-dataset).

Examples on how to write access level and policy YAML files are provided further down in this document.

### Default geo-based access level

The way we set up the perimeter for broad access is via a single geo-based access level, which is configured to allow access from one or more countries and deny all other traffic coming from outside the perimeter.

The [`datasets/classic/access-levels/geo.yaml`](datasets/classic/access-levels/geo.yaml) file serves as an example and **should be edited to contain the countries you need** (or replaced/removed for more granular configuration).

```yaml
conditions:
  - regions:
      # replace the following country codes with those you need
      - ES
      - IT
```

More access levels can be of course added to better tailor the configuration to specific needs. Some use cases are addressed further down in this document.

### Ingress policy for organization-level log sinks

An ingress policy that allows ingress to the perimeter for identities used in organization-level sinks is automatically created, but needs to be explicitly referenced in the perimeter via the `$identity_sets:logging_identities` context expansion.

This only supports sinks defined in the bootstrap stage, but it can easily be used as a reference for different, specific needs (or replaced with a policy leveraging Asset Inventory for automatic inclusion of folder-level sinks).

### Perimeter membership

The set of resources protected by each perimeter can be defined in two main ways:

- central and authoritative, where protected resources are only defined in this stage
- delegated and additive, where perimeter is defined in this stage and resources are added separately (e.g. by a project factory)

The first approach is more secure as it does not require granting editing permission to other actors, but it's also operationally heavier as it requires adding projects to the perimeter right after creation, before many operations can be run. For example, Shared VPC attachment for a service project cannot happen until the project is in the same perimeter as its host project. The main advantage of this approach is being able to leverage the resource discovery features provided by this stage.

The second approach is more flexible, but requires delegating a measure of control over perimeters to other actors, and losing control over perimeter membership which stops being enforced by Terraform.

When using the second approach, after applying this stage, provide perimeter information in your `defaults.yaml` file, for example:

```yaml
projects:
  overrides:
    vpc_sc:
      perimeter_name: accessPolicies/12345/servicePerimeters/default
```

And then apply `0-org-setup` stage again. For later stages (such as networking, project factory), add the perimeter in a similar way, but there you can use context to provide perimeter:

```yaml
projects:
  overrides:
    vpc_sc:
      perimeter_name: default
```

> [!CAUTION]
> Do not add any resources to the perimeter in this stage when using the second approach. Any resources added in this stage will not be properly removed from perimeter, if the `terraform apply` is also changing the perimeter definition.
>
#### Resource discovery

If the first approach is desired in combination with resource discovery, you can simply tweak exclusions via the `resource_discovery` variable as the feature is enabled by default.

Discovered resources are made available via the `$resource_sets:discovered_projects` context expansion, which is already part of the definition of the default perimeter.

This approach is suitable for simple requirements, and provided out of the box in this stage's default configuration.

#### Manual resource membership

When resource discovery is not used, resources can be added to perimeters via a combination of:

- explicit project numbers inclusion
- individual project expansion via the `$project_numbers:xxx` context namespace
- set-based project expansion via the `$resource_sets:xxx` context namespace

A selected number of auto-generated context expansions are generated by this stage, and described in the [Context section below](#stage-generated-contexts).This is what each of three methods above looks like in a perimeter definition.

```yaml
spec:
  resources:
    # explicit reference
    - projects/123456
    # individual expansion
    - $project_numbers:iac-0
    # set expansion
    - $resource_sets:org_setup_projects
```

When partial control is delegated to external actors, the perimeter needs to be configured to ignore changes to member resources so as not to trigger permadiffs between different stages. This is achieved via the `ignore_resource_changes` perimeter attribute.

```yaml
ignore_resource_changes: true
use_explicit_dry_run_spec: true
spec:
  # spec definition
```

### Enforced vs dry-run perimeters

As mentioned above, the default configuration uses a single perimeter configured in dry-run mode. A dry-run mode perimeter has the following format.

```yaml
# datasets/xxx/perimeters/myperimeter.yaml
use_explicit_dry_run_spec: true
spec:
  # perimeter definition here
```

A perimeter in enforced mode uses `status` instead of `spec`.

```yaml
# datasets/xxx/perimeters/myperimeter.yaml
use_explicit_dry_run_spec: true
status:
  # perimeter definition here
```

 If the dry-run and enforced configurations are different, define both explicitly in separate `spec` and `status` blocks, and set the `use_explicit_dry_run_spec` to `false`.

## Context expansion

In much the same way as other FAST stages and underlying modules, context expansion is supported here in two ways:

- static values can be defined in the stage's `defaults.yaml` file or `context` variable
- specific values derived by other FAST stages are automatically added to the relevant context namespaces

These are the available context namespaces in this stage.

| context           | type               |
| :---------------- | :----------------- |
| `iam_principals`  | `map(string)`      |
| `identity_sets`   | `map(map(string))` |
| `project_numbers` | `map(string)`      |
| `resource_sets`   | `map(map(string))` |
| `service_sets`    | `map(map(string))` |
| `storage_buckets` | `map(string)`      |

The following sub-sections illustrate how both work.

### Static contexts

Static contexts can be defined via the `defaults.yaml` file or the `context` variable, and are internally merged together and with the stage's built-in contexts.

This is an example of defining a context via `defaults.yaml`.

```yaml
# datasets/xxx/defaults.yaml
context:
  iam_principals:
    me: user:foo@example.com
  resource_sets:
    my_projects:
      - projects/12345
      - projects/67890
```

These can then be reused in YAML definitions like shown below.

```yaml
# datasets/xxx/perimeters/myperimeter.yaml
use_explicit_dry_run_spec: true
status:
  resources:
    - $resource_sets:my_projects
```

```yaml
# datasets/xxx/access-levels/identity_me.yaml
conditions:
  - members:
    - $iam_principals:me
```

### Stage-generated contexts

When this stage is used as part of a FAST installation, it consumes data made available from other stages and makes it available as context expansions. The resource discovery feature when enabled also add its own context expansion.

- `$iam_principals:service_accounts/xxx` \
  service accounts created in the 0-org-setup stage
- `$identity_sets:logging_identities` \
  set of identities used by the log sinks created in the 0-org-setup stage
- `$project_numbers:xxx` \
  project numbers for projects created in the 0-org-setup stage
- `$resource_sets:discovered_projects` \
  set of projects numbers for discovered projects (when discovery is enabled)
- `$resource_sets:org_setup_projects` \
  set of projects numbers for projects created in the 0-org-setup stage
- `$service_sets:restricted_services` \
  set of services defined in the services factory file
- `$storage_buckets:xxx` \
  storage buckets created in the 0-org-setup stage

## How to run this stage

This stage is meant to be executed after the [bootstrap](../0-org-setup) stage has run, as it leverages the automation service account and bucket created there. It does not depend from any other stage and no other stage requires it, so it can be run in any order or even skipped entirely.

It's of course possible to run this stage in isolation, but that's outside the scope of this document, and you would need to refer to the code for the previous stage for the environment requirements.

### Provider and Terraform variables

As all other FAST stages, the [mechanism used to pass variable values and pre-built provider files from one stage to the next](../0-org-setup/README.md#output-files-and-cross-stage-variables) is also leveraged here.

The commands to link or copy the provider and terraform variable files can be get from the `fast-links.sh` script in the FAST stages folder, passing it a single argument with the local output files folder or GCS output bucket. The following examples demonstrate both cases, and the resulting commands that then need to be copy/pasted and run.

```bash
../fast-links.sh ~/fast-config

# File linking commands for vpc service controls stage

# provider file
ln -s ~/fast-config/fast-test-00/providers/1-vpcsc-providers.tf ./

# input files from other stages
ln -s ~/fast-config/fast-test-00/tfvars/0-globals.auto.tfvars.json ./
ln -s ~/fast-config/fast-test-00/tfvars/0-org-setup.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
ln -s ~/fast-config/fast-test-00/1-vpcsc.auto.tfvars ./
```

```bash
# the outputs bucket name is in the stage 0 outputs and tfvars file
../fast-links.sh gs://xxx-prod-iac-core-outputs-0

# File linking commands for vpc service controls stage

# provider file
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/providers/1-vpcsc-providers.tf ./

# input files from other stages
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-org-setup.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/1-vpcsc.auto.tfvars ./
```

### Impersonating the automation service account

The preconfigured provider file uses impersonation to run with this stage's automation service account's credentials. The `gcp-devops` and `organization-admins` groups have the necessary IAM bindings in place to do that, so make sure the current user is a member of one of those groups.

### Variable configuration

Variables in this stage -- like most other FAST stages -- are broadly divided into three separate sets:

- variables which refer to global values for the whole organization (org id, billing account id, prefix, etc.), which are pre-populated via the `0-globals.auto.tfvars.json` file linked or copied above
- variables which refer to resources managed by previous stages, which are prepopulated here via the `0-org-setup.auto.tfvars.json` file linked or copied above
- and finally variables that optionally control this stage's behaviour and customizations, that you are expected to configure in a custom `terraform.tfvars` file

The latter set is explained in the [Customization](#customizations) sections below, and the full list can be found in the [Variables](#variables) table at the bottom of this document.

Note that the `outputs_location` variable is disabled by default, you need to explicitly set it in your `terraform.tfvars` file if you want output files to be generated by this stage. This is an example of doing it:

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

The stage is a thin wrapper that implements a single-perimeter design via the [`vpc-sc` module](../../../modules/vpc-sc/), and most of the customizations available in the module are also available here. A few examples are provided below for ease of reference.

### Access policy

The stage creates the org-level access policy by default. A pre-existing policy can instead be used by populating the `access_policy` variable with the policy id. In tenant-level mode this is done automatically by the FAST input/output files mechanism.

### Perimeters

The default perimeter is defined in the `perimeters/default.yaml` file within each dataset. The file can be easily customized and used as a basis to create additional perimeters.

```yaml
# yaml-language-server: $schema=../../../schemas/perimeter.schema.json

use_explicit_dry_run_spec: true
# default to dr-run
spec:
  access_levels:
    - geo
  # include discovered projects
  resources:
    - $resource_sets:discovered_projects
  ingress_policies:
    - fast-org-log-sinks
  # protect the full list of services
  restricted_services:
    - $service_sets:restricted_services

```

### Access levels

Access levels can be defined via tfvars or factory files using the same mechanism in the underlying [vpc-sc module](../../../modules/vpc-sc/).

These are example access levels defined via tfvars:

```tfvars
access_levels = {
  a1 = {
    conditions = [
      { members = ["user:user1@example.com"] }
    ]
  }
  a2 = {
    combining_function = "OR"
    conditions = [
      { regions = ["IT", "FR"] },
      { ip_subnetworks = ["101.101.101.0/24"] }
    ]
  }
}
```

And the same defined instead via factory files.

```yaml
# datasets/classic/access-levels/a1.yaml
conditions:
  - members:
    - "user:user1@example.com"
```

```yaml
# datasets/classic/access-levels/a2.yaml
combining_function: OR
conditions:
  - regions:
    - ES
    - IT
  - ip_subnetworks:
    - 8.8.0.0/16
```

Remember that in order for them to deployed, access levels need to be referenced by name in the perimeter definition.

### Ingress/egress policies

Like access levels, ingress and egress policies can be defined via tfvars or factory files using the same mechanism in the underlying [vpc-sc module](../../../modules/vpc-sc/).

This is an example ingress policy defined in yaml:

```yaml
# datasets/classic/ingress-policies/sa-tf-test.yaml
from:
  access_levels:
    - "*"
  identities:
    - serviceAccount:test-tf@myproject.iam.gserviceaccount.com
to:
  operations:
    - service_name: compute.googleapis.com
      method_selectors:
        - ProjectsService.Get
        - RegionsService.Get
  resources:
    - "*"
```

And this is an example egress policy:

```yaml
# datasets/classic/egress-policies/gcs-sa-foo.yaml
from:
  identities:
    - serviceAccount:foo@myproject.iam.gserviceaccount.com
to:
  operations:
    - method_selectors:
        - "*"
      service_name: storage.googleapis.com
  resources:
    - projects/123456789
```

Remember that in order for them to deployed, ingress/egress policies need to be referenced by name in the perimeter definition.

## Notes

Some references that might be useful in setting up this stage:

- [VPC SC CSCC requirements](https://cloud.google.com/security-command-center/docs/troubleshooting).

<!-- TFDOC OPTS files:1 show_extra:1 exclude:1-vpcsc-providers.tf -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [main.tf](./main.tf) | Module-level locals and resources. | <code>projects-data-source</code> · <code>vpc-sc</code> |  |
| [outputs.tf](./outputs.tf) | Module outputs. |  | <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [variables-fast.tf](./variables-fast.tf) | None |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [organization](variables-fast.tf#L35) | Organization details. | <code title="object&#40;&#123;&#10;  domain      &#61; string&#10;  id          &#61; number&#10;  customer_id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-org-setup</code> |
| [access_levels](variables.tf#L17) | Access level definitions. | <code title="map&#40;object&#40;&#123;&#10;  combining_function &#61; optional&#40;string&#41;&#10;  conditions &#61; optional&#40;list&#40;object&#40;&#123;&#10;    device_policy &#61; optional&#40;object&#40;&#123;&#10;      allowed_device_management_levels &#61; optional&#40;list&#40;string&#41;&#41;&#10;      allowed_encryption_statuses      &#61; optional&#40;list&#40;string&#41;&#41;&#10;      require_admin_approval           &#61; bool&#10;      require_corp_owned               &#61; bool&#10;      require_screen_lock              &#61; optional&#40;bool&#41;&#10;      os_constraints &#61; optional&#40;list&#40;object&#40;&#123;&#10;        os_type                    &#61; string&#10;        minimum_version            &#61; optional&#40;string&#41;&#10;        require_verified_chrome_os &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    ip_subnetworks         &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    members                &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    negate                 &#61; optional&#40;bool&#41;&#10;    regions                &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    required_access_levels &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    vpc_subnets            &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  description &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [access_policy](variables.tf#L67) | Access policy id (used for tenant-level VPC-SC configurations). | <code>number</code> |  | <code>null</code> |  |
| [context](variables.tf#L73) | External context used in replacements. | <code title="object&#40;&#123;&#10;  iam_principals  &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  identity_sets   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  project_numbers &#61; optional&#40;map&#40;number&#41;, &#123;&#125;&#41;&#10;  resource_sets   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  service_sets    &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  storage_buckets &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [egress_policies](variables.tf#L87) | Egress policy definitions that can be referenced in perimeters. | <code title="map&#40;object&#40;&#123;&#10;  title &#61; optional&#40;string&#41;&#10;  from &#61; object&#40;&#123;&#10;    access_levels &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    identity_type &#61; optional&#40;string&#41;&#10;    identities    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resources     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#10;  to &#61; object&#40;&#123;&#10;    external_resources &#61; optional&#40;list&#40;string&#41;&#41;&#10;    operations &#61; optional&#40;list&#40;object&#40;&#123;&#10;      method_selectors     &#61; optional&#40;list&#40;string&#41;&#41;&#10;      permission_selectors &#61; optional&#40;list&#40;string&#41;&#41;&#10;      service_name         &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    resources &#61; optional&#40;list&#40;string&#41;&#41;&#10;    roles     &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [factories_config](variables.tf#L130) | Paths to folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  dataset &#61; optional&#40;string, &#34;datasets&#47;classic&#34;&#41;&#10;  paths &#61; optional&#40;object&#40;&#123;&#10;    access_levels       &#61; optional&#40;string, &#34;access-levels&#34;&#41;&#10;    defaults            &#61; optional&#40;string, &#34;defaults.yaml&#34;&#41;&#10;    egress_policies     &#61; optional&#40;string, &#34;egress-policies&#34;&#41;&#10;    ingress_policies    &#61; optional&#40;string, &#34;ingress-policies&#34;&#41;&#10;    perimeters          &#61; optional&#40;string, &#34;perimeters&#34;&#41;&#10;    restricted_services &#61; optional&#40;string, &#34;restricted-services.yaml&#34;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [iam_principals](variables-fast.tf#L17) | Org-level IAM principals. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [ingress_policies](variables.tf#L147) | Ingress policy definitions that can be referenced in perimeters. | <code title="map&#40;object&#40;&#123;&#10;  title &#61; optional&#40;string&#41;&#10;  from &#61; object&#40;&#123;&#10;    access_levels &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    identity_type &#61; optional&#40;string&#41;&#10;    identities    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resources     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#10;  to &#61; object&#40;&#123;&#10;    operations &#61; optional&#40;list&#40;object&#40;&#123;&#10;      method_selectors     &#61; optional&#40;list&#40;string&#41;&#41;&#10;      permission_selectors &#61; optional&#40;list&#40;string&#41;&#41;&#10;      service_name         &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    resources &#61; optional&#40;list&#40;string&#41;&#41;&#10;    roles     &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [logging](variables-fast.tf#L25) | Log writer identities for organization / folders. | <code title="object&#40;&#123;&#10;  writer_identities &#61; map&#40;string&#41;&#10;  project_number    &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> | <code>0-org-setup</code> |
| [perimeters](variables.tf#L189) | Perimeter definitions. | <code title="map&#40;object&#40;&#123;&#10;  description               &#61; optional&#40;string&#41;&#10;  ignore_resource_changes   &#61; optional&#40;bool, false&#41;&#10;  title                     &#61; optional&#40;string&#41;&#10;  use_explicit_dry_run_spec &#61; optional&#40;bool, false&#41;&#10;  spec &#61; optional&#40;object&#40;&#123;&#10;    access_levels       &#61; optional&#40;list&#40;string&#41;&#41;&#10;    egress_policies     &#61; optional&#40;list&#40;string&#41;&#41;&#10;    ingress_policies    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    restricted_services &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resources           &#61; optional&#40;list&#40;string&#41;&#41;&#10;    vpc_accessible_services &#61; optional&#40;object&#40;&#123;&#10;      allowed_services   &#61; list&#40;string&#41;&#10;      enable_restriction &#61; optional&#40;bool, true&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  status &#61; optional&#40;object&#40;&#123;&#10;    access_levels       &#61; optional&#40;list&#40;string&#41;&#41;&#10;    egress_policies     &#61; optional&#40;list&#40;string&#41;&#41;&#10;    ingress_policies    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resources           &#61; optional&#40;list&#40;string&#41;&#41;&#10;    restricted_services &#61; optional&#40;list&#40;string&#41;&#41;&#10;    vpc_accessible_services &#61; optional&#40;object&#40;&#123;&#10;      allowed_services   &#61; list&#40;string&#41;&#10;      enable_restriction &#61; optional&#40;bool, true&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [project_numbers](variables-fast.tf#L46) | Project numbers. | <code>map&#40;number&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [resource_discovery](variables.tf#L223) | Automatic discovery of perimeter projects. | <code title="object&#40;&#123;&#10;  enabled          &#61; optional&#40;bool, true&#41;&#10;  ignore_folders   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  ignore_projects  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  include_projects &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [root_node](variables-fast.tf#L54) | Root node for the hierarchy, if running in tenant mode. | <code>string</code> |  | <code>null</code> | <code>0-org-setup</code> |
| [service_accounts](variables-fast.tf#L68) | Org-level service accounts. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [storage_buckets](variables-fast.tf#L76) | Storage buckets created in the bootstrap stage. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [tfvars](outputs.tf#L52) | Terraform variable files for the following stages. | ✓ |  |
| [vpc_sc_perimeter_default](outputs.tf#L58) | Raw default perimeter resource. | ✓ |  |
<!-- END TFDOC -->
