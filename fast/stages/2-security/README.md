# Shared Security Resources

This stage sets up an area dedicated to hosting security resources and configurations which impact the whole organization, or are shared across the hierarchy to other projects and teams.

Like other modern FAST stage, the resource design is defined here via YAML configuration files and implemented via factories to provide maximum flexibility. A sample reference design compatible with legacy FAST is provided in an initial dataset, and can be used as-is or used as a basis for customizations.

The following diagram illustrates the high-level design of resources implemented in the default dataset:

<p align="center">
  <img src="diagram.png" alt="Security diagram">
</p>

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
  - [Cloud KMS](#cloud-kms)
  - [Certificate Authority Service (CAS)](#certificate-authority-service-cas)
- [How to run this stage](#how-to-run-this-stage)
  - [Provider and Terraform variables](#provider-and-terraform-variables)
  - [Impersonating the automation service account](#impersonating-the-automation-service-account)
  - [Variable configuration](#variable-configuration)
  - [Using delayed billing association for projects](#using-delayed-billing-association-for-projects)
  - [Running the stage](#running-the-stage)
- [Customizations](#customizations)
  - [KMS keys](#kms-keys)
  - [NGFW Enterprise - sample TLS configurations](#ngfw-enterprise-sample-tls-configurations)
- [Files](#files)
- [Variables](#variables)
<!-- END TOC -->

## Design overview and choices

Project-level security resources are grouped into two separate projects, one per environment. This setup matches requirements we frequently observe in real life and provides enough separation without needlessly complicating operations.

Cloud KMS is configured and designed mainly to encrypt GCP resources with a [Customer-managed encryption key](https://cloud.google.com/kms/docs/cmek) but it may be used to create cryptokeys used to [encrypt application data](https://cloud.google.com/kms/docs/encrypting-application-data) too.

IAM for day to day operations is already assigned at the folder level to the security team by the previous stage, but more granularity can be added here at the project level, to grant control of separate services across environments to different actors.

### Cloud KMS

A reference Cloud KMS implementation is part of this stage, to provide a simple way of managing centralized keys, that are then shared and consumed widely across the organization to enable customer-managed encryption. The implementation is also easy to clone and modify to support other services like Secret Manager.

The Cloud KMS configuration allows defining keys by name (typically matching the downstream service that uses them) in different locations. It then takes care internally of provisioning the relevant keyrings and creating keys in the appropriate location.

IAM roles on keys can be configured at the logical level for all locations where a logical key is created. Their management can also be delegated via [delegated role grants](https://cloud.google.com/iam/docs/setting-limits-on-granting-roles) exposed through a simple variable, to allow other identities to set IAM policies on keys. This is particularly useful in setups like project factories, making it possible to configure IAM bindings during project creation for team groups or service agent accounts (compute, storage, etc.).

### Certificate Authority Service (CAS)

With this stage you can leverage Certificate Authority Services (CAS) and create as many CAs you need for each environments. To create custom CAS, you can use the `certificate_authorities` variable.

## How to run this stage

This stage is meant to be executed after the [bootstrap](../0-org-setup) stage has run, as it leverages the automation service account and bucket created there, and additional resources configured there.

It's of course possible to run this stage in isolation, but that's outside the scope of this document, and you would need to refer to the code for the previous stages for the environmental requirements.

Before running this stage, you need to make sure you have the correct credentials and permissions, and localize variables by assigning values that match your configuration.

### Provider and Terraform variables

As all other FAST stages, the [mechanism used to pass variable values and pre-built provider files from one stage to the next](../0-org-setup/README.md#output-files-and-cross-stage-variables) is also leveraged here.

The commands to link or copy the provider and terraform variable files can be easily derived from the `fast-links.sh` script in the FAST stages folder, passing it a single argument with the local output files folder (if configured) or the GCS output bucket in the automation project (derived from stage 0 outputs). The following examples demonstrate both cases, and the resulting commands that then need to be copy/pasted and run.

```bash
../fast-links.sh ~/fast-config

# File linking commands for security stage

# provider file
ln -s ~/fast-config/fast-test-00/providers/2-security-providers.tf ./

# input files from other stages
ln -s ~/fast-config/fast-test-00/tfvars/0-globals.auto.tfvars.json ./
ln -s ~/fast-config/fast-test-00/tfvars/0-org-setup.auto.tfvars.json ./
ln -s ~/fast-config/fast-test-00/tfvars/1-resman.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
ln -s ~/fast-config/fast-test-00/2-security.auto.tfvars ./

# optional files
ln -s ~/fast-config/fast-test-00/2-nsec.auto.tfvars.json ./
```

```bash
../fast-links.sh gs://xxx-prod-iac-core-outputs-0

# File linking commands for security stage

# provider file
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/providers/2-security-providers.tf ./

# input files from other stages
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-org-setup.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/1-resman.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/2-security.auto.tfvars ./

# optional files
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/2-nsec.auto.tfvars.json ./
```

### Impersonating the automation service account

The preconfigured provider file uses impersonation to run with this stage's automation service account's credentials. The `gcp-devops` and `organization-admins` groups have the necessary IAM bindings in place to do that, so make sure the current user is a member of one of those groups.

### Variable configuration

Variables in this stage -- like most other FAST stages -- are broadly divided into three separate sets:

- variables which refer to global values for the whole organization (org id, billing account id, prefix, etc.), which are pre-populated via the `0-globals.auto.tfvars.json` file linked or copied above
- variables which refer to resources managed by previous stages, which are prepopulated here via the `0-org-setup.auto.tfvars.json` and `1-resman.auto.tfvars.json` files linked or copied above
- and finally variables that optionally control this stage's behaviour and customizations, and can to be set in a custom `terraform.tfvars` file

The latter set is explained in the [Customization](#customizations) sections below, and the full list can be found in the [Variables](#variables) table at the bottom of this document.

Note that the `outputs_location` variable is disabled by default, you need to explicitly set it in your `terraform.tfvars` file if you want output files to be generated by this stage. This is a sample `terraform.tfvars` that configures it, refer to the [bootstrap stage documentation](../0-org-setup/README.md#output-files-and-cross-stage-variables) for more details:

```tfvars
outputs_location = "~/fast-config"
```

### Using delayed billing association for projects

This configuration is possible but unsupported and only exists for development purposes, use at your own risk:

- temporarily switch `billing_account.id` to `null` in `0-globals.auto.tfvars.json`
- for each project resources in the project modules used in this stage (`dev-sec-project`, `prod-sec-project`)
  - apply using `-target`, for example
    `terraform apply -target 'module.prod-sec-project.google_project.project[0]'`
  - untaint the project resource after applying, for example
    `terraform untaint 'module.prod-sec-project.google_project.project[0]'`
- go through the process to associate the billing account with the two projects
- switch `billing_account.id` back to the real billing account id
- resume applying normally

### Running the stage

Once provider and variable values are in place and the correct user is configured, the stage can be run:

```bash
terraform init
terraform apply
```

## Customizations

### KMS keys

Cloud KMS configuration is controlled by `kms_keys`, which configures the actual keys to create, and also allows configuring their IAM bindings, labels, locations and rotation period. When configuring locations for a key, please consider the limitations each cloud product may have.

The additional `kms_restricted_admins` variable allows granting `roles/cloudkms.admin` to specified principals, restricted via [delegated role grants](https://cloud.google.com/iam/docs/setting-limits-on-granting-roles) so that it only allows granting the roles needed for encryption/decryption on keys. This allows safe delegation of key management to subsequent Terraform stages like the Project Factory, for example to grant usage access on relevant keys to the service agent accounts for compute, storage, etc.

To support these scenarios, key IAM bindings are configured by default to be additive, to enable other stages or Terraform configuration to safely co-manage bindings on the same keys. If this is not desired, follow the comments in the `core-dev.tf` and `core-prod.tf` files to switch to authoritative bindings on keys.

An example of how to configure keys:

```tfvars
# terraform.tfvars

kms_keys = {
  compute = {
    iam = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "user:user1@example.com"
      ]
    }
    labels          = { service = "compute" }
    locations       = ["europe-west1", "europe-west3", "global"]
    rotation_period = "7776000s"
  }
  storage = {
    iam             = null
    labels          = { service = "storage" }
    locations       = ["europe"]
    rotation_period = null
  }
}
```

The script will create one keyring for each specified location and keys on each keyring.

### NGFW Enterprise - sample TLS configurations

This is a minimal configuration that creates a CAs for each environment and enables TLS inspection policies for NGFW Enterprise.

```tfvars
cas_configs = {
  dev = {
    ngfw-dev-cas-0 = {
      location = "europe-west1"
    }
  }
  prod = {
    ngfw-prod-cas-0 = {
      location = "europe-west1"
    }
  }
}
tls_inspection = {
  enabled = true
}
```

You can optionally create also trust-configs for NGFW Enterprise.

```tfvars
cas_configs = {
  dev = {
    ngfw-dev-cas-0 = {
      location = "europe-west1"
    }
  }
  prod = {
    ngfw-prod-cas-0 = {
      location = "europe-west1"
    }
  }
}
trust_configs = {
  dev = {
    ngfw-dev-tc-0 = {
      allowlisted_certificates = {
        my_ca = "~/my_keys/srv-dev.crt"
      }
      location = "europe-west1"
    }
  }
  prod = {
    ngfw-prod-tc-0 = {
      allowlisted_certificates = {
        my_ca = "~/my_keys/srv-prod.crt"
      }
      location = "europe-west1"
    }
  }
}
tls_inspection = {
  enabled = true
}
```

You can customize the keys of your configurations, as long as they match the ones you specify in the `ngfw_tls_configs.keys` variable.

```tfvars
cas_configs = {
  dev = {
    my-ca-0 = {
      location = "europe-west1"
    }
  }
}
ngfw_tls_configs = {
  keys = {
    dev = {
      cas = "my-ca-0"
    }
  }
}
tls_inspection = {
  enabled = true
}
```

<!-- TFDOC OPTS files:1 show_extra:1 exclude:2-security-providers.tf -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [factory-cas.tf](./factory-cas.tf) | None | <code>certificate-authority-service</code> |  |
| [factory-keyrings.tf](./factory-keyrings.tf) | None | <code>kms</code> |  |
| [factory-projects.tf](./factory-projects.tf) | None | <code>project-factory</code> |  |
| [main.tf](./main.tf) | Module-level locals and resources. |  |  |
| [outputs.tf](./outputs.tf) | Module outputs. |  | <code>google_storage_bucket_object</code> |
| [variables-fast.tf](./variables-fast.tf) | None |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [automation](variables-fast.tf#L17) | Automation resources created by the bootstrap stage. | <code title="object&#40;&#123;&#10;  outputs_bucket &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-org-setup</code> |
| [billing_account](variables-fast.tf#L26) | Billing account id. | <code title="object&#40;&#123;&#10;  id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-org-setup</code> |
| [prefix](variables-fast.tf#L74) | Prefix used for resources that need unique names. Use a maximum of 9 chars for organizations, and 11 chars for tenants. | <code>string</code> | ✓ |  | <code>0-org-setup</code> |
| [context](variables.tf#L17) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  condition_vars    &#61; optional&#40;map&#40;map&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  custom_roles      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  folder_ids        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations         &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids       &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_keys          &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_values        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  vpc_sc_perimeters &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [custom_roles](variables-fast.tf#L34) | Custom roles defined at the org level, in key => id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [factories_config](variables.tf#L34) | Configuration for the resource factories or external data. | <code title="object&#40;&#123;&#10;  certificate_authorities &#61; optional&#40;string&#41; &#35; &#34;data&#47;certificate-authorities&#34;&#10;  defaults                &#61; optional&#40;string, &#34;data&#47;defaults.yaml&#34;&#41;&#10;  folders                 &#61; optional&#40;string, &#34;data&#47;folders&#34;&#41;&#10;  keyrings                &#61; optional&#40;string, &#34;data&#47;keyrings&#34;&#41;&#10;  projects                &#61; optional&#40;string, &#34;data&#47;projects&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [folder_ids](variables-fast.tf#L42) | Folders created in the bootstrap stage. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [iam_principals](variables-fast.tf#L50) | IAM-format principals. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [kms_keys](variables-fast.tf#L58) | KMS key ids. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>2-security</code> |
| [perimeters](variables-fast.tf#L66) | Optional VPC-SC perimeter ids. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>1-vpcsc</code> |
| [project_ids](variables-fast.tf#L84) | Projects created in the bootstrap stage. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [service_accounts](variables-fast.tf#L92) | Service accounts created in the bootstrap stage. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [tag_keys](variables-fast.tf#L100) | FAST-managed resource manager tag keys. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
| [tag_values](variables-fast.tf#L108) | FAST-managed resource manager tag values. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-org-setup</code> |
<!-- END TFDOC -->
