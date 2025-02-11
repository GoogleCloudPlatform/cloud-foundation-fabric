# Network Test Resources

This add-on allows creating an arbitrary number of Compute instances and service accounts, and is designed to simplify testing of the FAST networking stage.

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
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

The add-on is very simple, as it just deals with creating service accounts and instances using pre-existing projects, networks and subnets.

To allow creation of portable configurations, it extensively leverages FAST output variables so that project ids, network ids, regions, and subnet ids can refer to the relevant FAST aliases.

A simple factory is also provided, so that YAML configurations can be used instead of Terraform tfvars.

## How to run this stage

Once the main networking stage has been configured and applied, the following configuration is added the the resource management `fast_addon` variable to create the add-on provider files, and its optional CI/CD resources if those are also required. The add-on name (`networking-test`) is customizable, in case the add-on needs to be run multiple times to create gateways in different projects.

```hcl
fast_addon = {
  networking-test = {
    parent_stage = "2-networking"
  }
}
```

### Provider and Terraform variables

As all other FAST stages, the [mechanism used to pass variable values and pre-built provider files from one stage to the next](../../stages/0-bootstrap/README.md#output-files-and-cross-stage-variables) is also leveraged here.

The commands to link or copy the provider and terraform variable files can be easily derived from the `fast-links.sh` script in the FAST stages folder, passing it a single argument with the local output files folder (if configured) or the GCS output bucket in the automation project (derived from stage 0 outputs). The following example uses local files but GCS behaves identically.

```bash
# File linking commands for Test resources networking add-on stage

# provider file
ln -s ~/fast-config/providers/2-networking-test-providers.tf ./

# input files from other stages
ln -s ~/fast-config/tfvars/2-networking.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
ln -s ~/fast-config/2-networking-test.auto.tfvars ./
```

If a factory is used and neither the default factory paths nor the resource name prefix in the `name` variable need to be changed, the last file is unnecessary as there's no additional configuration for this add-on.

### Impersonating the automation service account

The preconfigured provider file uses impersonation to run with this stage's automation service account's credentials. The `gcp-devops` and `organization-admins` groups have the necessary IAM bindings in place to do that, so make sure the current user is a member of one of those groups.

### Variable configuration

Variables in this stage -- like most other FAST stages -- are broadly divided into three separate sets:

- variables which refer to global values for the whole organization (org id, billing account id, prefix, etc.), which are pre-populated via the `0-globals.auto.tfvars.json` file linked or copied above
- variables which refer to resources managed by previous stages, which are prepopulated here via the `0-bootstrap.auto.tfvars.json`, `1-resman.auto.tfvars.json` and `2-networking.auto.tfvars.json` files linked or copied above
- and finally variables that optionally control this stage's behaviour and customizations, and can to be set in a custom `terraform.tfvars` file

The first two sets are defined in the `variables-fast.tf` file, the latter set in the `variables.tf` file. The full list of variables can be found in the [Variables](#variables) table at the bottom of this document.

Once output files are in place, define your addon configuration in a tfvars file if needed (see section above).

### Running the stage

Once provider and variable values are in place and the correct user is configured, the stage can be run:

```bash
terraform init
terraform apply
```

<!-- TFDOC OPTS files:1 show_extra:1 exclude:2-networking-test-providers.tf -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules |
|---|---|---|
| [context.tf](./context.tf) | FAST context locals |  |
| [factory.tf](./factory.tf) | Factory locals. |  |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>compute-vm</code> · <code>iam-service-account</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [variables-fast.tf](./variables-fast.tf) | FAST stage interface. |  |
| [variables.tf](./variables.tf) | Module variables. |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [factories_config](variables.tf#L17) | Configuration for the resource factories. | <code title="object&#40;&#123;&#10;  instances        &#61; optional&#40;string, &#34;data&#47;instances&#34;&#41;&#10;  service_accounts &#61; optional&#40;string, &#34;data&#47;service-accounts&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [host_project_ids](variables-fast.tf#L19) | Networking stage host project id aliases. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
| [name](variables.tf#L27) | Prefix used for all resource names. | <code>string</code> |  | <code>&#34;test&#34;</code> |  |
| [regions](variables-fast.tf#L27) | Region aliases. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
| [subnet_self_links](variables-fast.tf#L35) | Subnet self links. | <code>map&#40;map&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |
| [test_instances](variables.tf#L34) | Test instances to be created. | <code title="map&#40;object&#40;&#123;&#10;  project_id      &#61; string&#10;  network_id      &#61; string&#10;  service_account &#61; string&#10;  subnet_id       &#61; string&#10;  image           &#61; optional&#40;string&#41;&#10;  metadata        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tags            &#61; optional&#40;list&#40;string&#41;, &#91;&#34;ssh&#34;&#93;&#41;&#10;  type            &#61; optional&#40;string, &#34;e2-micro&#34;&#41;&#10;  user_data_file  &#61; optional&#40;string&#41;&#10;  zones           &#61; optional&#40;list&#40;string&#41;, &#91;&#34;b&#34;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [test_service_accounts](variables.tf#L52) | Service accounts used by instances. | <code title="map&#40;object&#40;&#123;&#10;  project_id        &#61; string&#10;  display_name      &#61; optional&#40;string&#41;&#10;  iam_project_roles &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [vpc_self_links](variables-fast.tf#L43) | VPC network self links. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-networking</code> |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [instance_addresses](outputs.tf#L17) | Instance names and addresses. |  |  |
| [instance_ssh](outputs.tf#L24) | Instance SSH commands. |  |  |
| [service_account_emails](outputs.tf#L33) | Service account emails. |  |  |
<!-- END TFDOC -->
