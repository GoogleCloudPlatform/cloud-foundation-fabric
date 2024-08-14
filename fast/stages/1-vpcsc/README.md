# VPC Service Controls

This stage sets up VPC Service Controls (VPC-SC) for the whole organization and is a thing FAST-compliant wrapper on the [VPC-SC module](../../../modules/vpc-sc/), with some minimal defaults.

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
  - [Single perimeter with built-in extensibility](#single-perimeter-with-built-in-extensibility)
  - [Factories for VPC-SC configuration](#factories-for-vpc-sc-configuration)
  - [Default geo-based access level](#default-geo-based-access-level)
  - [Ingress policy for organization-level log sinks](#ingress-policy-for-organization-level-log-sinks)
  - [Asset Inventory for perimeter membership](#asset-inventory-for-perimeter-membership)
- [How to run this stage](#how-to-run-this-stage)
  - [Provider and Terraform variables](#provider-and-terraform-variables)
  - [Impersonating the automation service account](#impersonating-the-automation-service-account)
  - [Variable configuration](#variable-configuration)
  - [Running the stage](#running-the-stage)
- [Customizations](#customizations)
  - [Access policy](#access-policy)
  - [Default perimeter](#default-perimeter)
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

The perimeter is set to dry-run mode by default, but the suggestion is to switch to enforced mode immediately after definining the initial set of access level and ingress/egress policies. This prevents the common situation where a complex design is deployed in dry-run mode, and then never enforced as the burden of addressing all violations is too high. A simpler design like the one presented here that employs very coarse access levels can be enforced quickly, and then refined iteratively as operations are streamlined and familiarity with VPC-SC quirks increases.

The stage is designed to allow definining additional perimeters via the `perimeters` variable, with a few caveats:

- there's no support for perimeter bridges, if those are needed they need to be integrated via code (which is easy enough to do anyway)
- resource discovery is only supported for the default perimeter, using the `default` key in the `perimeters` variable (again, that is reasonably easy to change via code if needed)
- the factory files for access levels and ingress/egress policies use the same folder regardless of perimeter, but their inclusion in a perimeter is controlled by the individual perimeters `access_levels`, `ingress_policies`, and `egress_policies` attributes.

### Factories for VPC-SC configuration

Restricted services, access levels, ingress and egress policies can all be configured via YAML-based files, which allow intuitive editing and minimize the complexity of running operations.

The default setup only contains a single access level and an initial list of restricted services in the `data/access-levels` folder and the `data/restricted-services.yaml` file.

To configure ingress and egress policies simply add `ingress_policies` and/or `egress_policies` folders under `data`, or point the factories to your own folders by changing the `factories_config` variable values.

Examples on how to write access level and policy YAML files are provided further down in this document.

### Default geo-based access level

The way we set up the perimeter for broad access is via a single geo-based access level, which is configured to allow access from one or more countries and deny all other traffic coming from outside the perimeter.

The [`data/access-levels/geo.yaml`](data/access-levels/geo.yaml) file serves as an example and **should be edited to contain the countries you need** (or replaced/removed for more granular configuration).

```yaml
conditions:
  - regions:
      # replace the following country codes with those you need
      - ES
      - IT
```

More access levels can be of course added to better tailor the configuration to specific needs. Some use cases are addressed further down in this document.

### Ingress policy for organization-level log sinks

An ingress policy that allows ingress to the perimeter for identities used in organization-level sinks is automatically created, but needs to be explicitly referenced in the perimeter via the `fast-org-log-sinks` key.

This only supports sinks defined in the bootstrap stage, but it can easily be used as a reference for different, specific needs (or replaced with a policy leveraging Asset Inventory for automatic inclusion of folder-level sinks).

### Asset Inventory for perimeter membership

One more feature this setup provides out of the box to reduce toil, is semi-automatic resource discovery and management of perimeter membership via Cloud Asset Inventory.

This is only supported for the `default` perimeters, and requires this stage to be run every time new projects are created. It is mainly meant for simple installations where project churn is low and the organization is fairly stable. For large installations, direct perimeter inclusion of projects at creation time via the project factory is probably a better choice.

Resource discovery can be configured (or turned off if needed) via the `resource_discovery` variable.

## How to run this stage

This stage is meant to be executed after the [bootstrap](../0-bootstrap) stage has run, as it leverages the automation service account and bucket created there. It does not depend from any other stage and no other stage requires it, so it can be run in any order or even skipped entirely.

It's of course possible to run this stage in isolation, but that's outside the scope of this document, and you would need to refer to the code for the previous stage for the environment requirements.

### Provider and Terraform variables

As all other FAST stages, the [mechanism used to pass variable values and pre-built provider files from one stage to the next](../0-bootstrap/README.md#output-files-and-cross-stage-variables) is also leveraged here.

The commands to link or copy the provider and terraform variable files can be get from the `stage-links.sh` script in the FAST root folder, passing it a single argument with the local output files folder or GCS output bucket. The following examples demonstrate both cases, and the resulting commands that then need to be copy/pasted and run.

```bash
../../stage-links.sh ~/fast-config

# copy and paste the following commands for '1-vpcsc'

ln -s ~/fast-config/tfvars/0-globals.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/0-bootstrap.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/1-resman.auto.tfvars.json ./
```

```bash
# the outputs bucket name is in the stage 0 outputs and tfvars file
../../stage-links.sh gs://xxx-prod-iac-core-outputs-0

# copy and paste the following commands for '2-security'

gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./
gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/1-resman.auto.tfvars.json ./
```

### Impersonating the automation service account

The preconfigured provider file uses impersonation to run with this stage's automation service account's credentials. The `gcp-devops` and `organization-admins` groups have the necessary IAM bindings in place to do that, so make sure the current user is a member of one of those groups.

### Variable configuration

Variables in this stage -- like most other FAST stages -- are broadly divided into three separate sets:

- variables which refer to global values for the whole organization (org id, billing account id, prefix, etc.), which are pre-populated via the `0-globals.auto.tfvars.json` file linked or copied above
- variables which refer to resources managed by previous stages, which are prepopulated here via the `0-bootstrap.auto.tfvars.json` file linked or copied above
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

### Default perimeter

The default perimeter is exposed via the `perimeters.default` variable which allows customizing most of its features.

The only exception is the list of restricted services, which is configured via a YAML file with a list of services. To configure restricted services edit the list in `data/restricted-services.yaml`, or set the list of services in the `restricted_services` perimeter attribute.

Note that it's not enough to define access levels and ingress/egress policies via their variables or via factory files: in order for them to be deployed they also need to be referenced by name in the perimeter via the attributes shown in this example.

```tfvars
perimeters = {
  default = {
    # enable access levels defined in YAML and/or variables
    access_levels    = ["geo"]
    # switch to enforced mode (defaults to true)
    dry_run          = false
    # enable egress policies defined in YAML and/or variables
    egress_policies  = []
    # enable ingress policies defined in YAML and/or variables
    # and/or the built-in ingress policy for org-level log sinks
    ingress_policies = ["fast-org-log-sinks"]
    # list resources part of this perimeter
    resources        = []
    # turn on VPC accessible services
    vpc_accessible_services = {
      allowed_services   = []
      enable_restriction = false
    }
  }
}
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
# data/access-levels/a1.yaml
conditions:
  - members:
    - "user:user1@example.com"
```

```yaml
# data/access-levels/a2.yaml
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
# data/ingress-policies/sa-tf-test.yaml
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
# data/egress-policies/gcs-sa-foo.yaml
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

<!-- TFDOC OPTS files:1 show_extra:1 -->
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
| [automation](variables-fast.tf#L17) | Automation resources created by the bootstrap stage. | <code title="object&#40;&#123;&#10;  outputs_bucket &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [organization](variables-fast.tf#L35) | Organization details. | <code title="object&#40;&#123;&#10;  domain      &#61; string&#10;  id          &#61; number&#10;  customer_id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [access_levels](variables.tf#L17) | Access level definitions. | <code title="map&#40;object&#40;&#123;&#10;  combining_function &#61; optional&#40;string&#41;&#10;  conditions &#61; optional&#40;list&#40;object&#40;&#123;&#10;    device_policy &#61; optional&#40;object&#40;&#123;&#10;      allowed_device_management_levels &#61; optional&#40;list&#40;string&#41;&#41;&#10;      allowed_encryption_statuses      &#61; optional&#40;list&#40;string&#41;&#41;&#10;      require_admin_approval           &#61; bool&#10;      require_corp_owned               &#61; bool&#10;      require_screen_lock              &#61; optional&#40;bool&#41;&#10;      os_constraints &#61; optional&#40;list&#40;object&#40;&#123;&#10;        os_type                    &#61; string&#10;        minimum_version            &#61; optional&#40;string&#41;&#10;        require_verified_chrome_os &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    ip_subnetworks         &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    members                &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    negate                 &#61; optional&#40;bool&#41;&#10;    regions                &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    required_access_levels &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  description &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [access_policy](variables.tf#L56) | Access policy id (used for tenant-level VPC-SC configurations). | <code>number</code> |  | <code>null</code> |  |
| [egress_policies](variables.tf#L62) | Egress policy definitions that can be referenced in perimeters. | <code title="map&#40;object&#40;&#123;&#10;  from &#61; object&#40;&#123;&#10;    identity_type &#61; optional&#40;string&#41;&#10;    identities    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#10;  to &#61; object&#40;&#123;&#10;    operations &#61; optional&#40;list&#40;object&#40;&#123;&#10;      method_selectors     &#61; optional&#40;list&#40;string&#41;&#41;&#10;      permission_selectors &#61; optional&#40;list&#40;string&#41;&#41;&#10;      service_name         &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    resources              &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resource_type_external &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [factories_config](variables.tf#L93) | Paths to folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  access_levels    &#61; optional&#40;string, &#34;data&#47;access-levels&#34;&#41;&#10;  egress_policies  &#61; optional&#40;string, &#34;data&#47;egress-policies&#34;&#41;&#10;  ingress_policies &#61; optional&#40;string, &#34;data&#47;ingress-policies&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [ingress_policies](variables.tf#L104) | Ingress policy definitions that can be referenced in perimeters. | <code title="map&#40;object&#40;&#123;&#10;  from &#61; object&#40;&#123;&#10;    access_levels &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    identity_type &#61; optional&#40;string&#41;&#10;    identities    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resources     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#10;  to &#61; object&#40;&#123;&#10;    operations &#61; optional&#40;list&#40;object&#40;&#123;&#10;      method_selectors     &#61; optional&#40;list&#40;string&#41;&#41;&#10;      permission_selectors &#61; optional&#40;list&#40;string&#41;&#41;&#10;      service_name         &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    resources &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [logging](variables-fast.tf#L25) | Log writer identities for organization / folders. | <code title="object&#40;&#123;&#10;  project_number    &#61; string&#10;  writer_identities &#61; map&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> | <code>0-bootstrap</code> |
| [outputs_location](variables.tf#L136) | Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable. | <code>string</code> |  | <code>null</code> |  |
| [perimeters](variables.tf#L142) | Perimeter definitions. | <code title="map&#40;object&#40;&#123;&#10;  access_levels       &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  dry_run             &#61; optional&#40;bool, true&#41;&#10;  egress_policies     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  ingress_policies    &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  resources           &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  restricted_services &#61; optional&#40;list&#40;string&#41;&#41;&#10;  vpc_accessible_services &#61; optional&#40;object&#40;&#123;&#10;    allowed_services   &#61; list&#40;string&#41;&#10;    enable_restriction &#61; optional&#40;bool, true&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  default &#61; &#123;&#10;    access_levels    &#61; &#91;&#34;geo&#34;&#93;&#10;    ingress_policies &#61; &#91;&#34;fast-org-log-sinks&#34;&#93;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [resource_discovery](variables.tf#L165) | Automatic discovery of perimeter projects. | <code title="object&#40;&#123;&#10;  enabled          &#61; optional&#40;bool, true&#41;&#10;  ignore_folders   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  ignore_projects  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  include_projects &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [root_node](variables-fast.tf#L45) | Root node for the hierarchy, if running in tenant mode. | <code>string</code> |  | <code>null</code> | <code>0-bootstrap</code> |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [tfvars](outputs.tf#L43) | Terraform variable files for the following stages. | ✓ |  |
| [vpc_sc_perimeter_default](outputs.tf#L49) | Raw default perimeter resource. | ✓ |  |
<!-- END TFDOC -->
