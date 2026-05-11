# Looker Core module

This module manages the creation of a [Looker Core instance](https://cloud.google.com/looker/docs/looker-core).

This module accepts Oauth client ID and secret in the input variable `oauth_config`. You must specify the `client_id` and `client_secret` strings for a pre-existing oauth client. You can [set up an oauth client and credentials](https://cloud.google.com/looker/docs/looker-core-create-oauth) manually.

> [!WARNING]
> Please be aware that, at the time of this writing, deleting the looker core instance via terraform is not possible due
> to <https://github.com/hashicorp/terraform-provider-google/issues/19467>. The work-around is to delete the instance from the
> console (or gcloud with force option) and remove the corresponding resource from the terraform state.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Simple example](#simple-example)
  - [Looker Core private instance with PSA](#looker-core-private-instance-with-psa)
  - [Looker Core with PSC](#looker-core-with-psc)
  - [Looker Core full example](#looker-core-full-example)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

### Simple example

This example shows how to set up a public Looker Core instance.

```hcl
module "looker" {
  source     = "./fabric/modules/looker-core"
  project_id = var.project_id
  region     = var.region
  name       = "looker"
  network_config = {
    public = true
  }
  oauth_config = {
    client_id     = "xxxxxxxxx"
    client_secret = "xxxxxxxx"
  }
}
# tftest modules=1 resources=1 inventory=simple.yaml
```

### Looker Core private instance with PSA

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  parent          = var.folder_id
  name            = "looker"
  prefix          = var.prefix
  services = [
    "servicenetworking.googleapis.com",
    "looker.googleapis.com",
  ]
}

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = module.project.project_id
  name       = "my-network"
  psa_configs = [
    {
      ranges = { looker = "10.60.0.0/16" }
    }
  ]
}

module "looker" {
  source     = "./fabric/modules/looker-core"
  project_id = module.project.project_id
  region     = var.region
  name       = "looker"
  network_config = {
    psa_config = {
      network = module.vpc.id
    }
  }
  oauth_config = {
    client_id     = "xxxxxxxxx"
    client_secret = "xxxxxxxx"
  }
  platform_edition = "LOOKER_CORE_ENTERPRISE_ANNUAL"
}
# tftest modules=3 resources=15 inventory=psa.yaml
```


### Looker Core with PSC

```hcl
module "looker" {
  source     = "./fabric/modules/looker-core"
  project_id = var.project_id
  region     = var.region
  name       = "looker-psc"
  network_config = {
    psc_config = {
      allowed_vpcs = ["projects/test-project/global/networks/test"]
    }
  }
  oauth_config = {
    client_id     = "xxxxxxxxx"
    client_secret = "xxxxxxxx"
  }
  platform_edition = "LOOKER_CORE_ENTERPRISE_ANNUAL"
}
# tftest inventory=psc.yaml
```

### Looker Core full example

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  parent          = var.folder_id
  name            = "looker"
  prefix          = var.prefix
  services = [
    "cloudkms.googleapis.com",
    "iap.googleapis.com",
    "looker.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = module.project.project_id
  name       = "my-network"
  psa_configs = [
    {
      ranges = { looker = "10.60.0.0/16" }
    }
  ]
}

module "kms" {
  source     = "./fabric/modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = var.region
    name     = "keyring"
  }
  keys = {
    "key-regional" = {
    }
  }
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      module.project.service_agents.looker.iam_email
    ]
  }
}

module "looker" {
  source     = "./fabric/modules/looker-core"
  project_id = module.project.project_id
  region     = var.region
  name       = "looker"
  admin_settings = {
    allowed_email_domains = ["google.com"]
  }
  encryption_config = {
    kms_key_name = module.kms.keys.key-regional.id
  }
  network_config = {
    psa_config = {
      network = module.vpc.id
    }
  }
  oauth_config = {
    client_id     = "xxxxxxxxx"
    client_secret = "xxxxxxxx"
  }
  platform_edition = "LOOKER_CORE_ENTERPRISE_ANNUAL"
}
# tftest modules=4 resources=23 inventory=full.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L113) | Name of the looker core instance. | <code>string</code> | ✓ |  |
| [network_config](variables.tf#L118) | Network configuration for cluster and instance. Only one between psa_config, psc_config and public can be used. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [oauth_config](variables.tf#L147) | Looker Core Oauth config. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L190) | The ID of the project where this instances will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L195) | Region for the Looker core instance. | <code>string</code> | ✓ |  |
| [admin_settings](variables.tf#L17) | Looker Core admins settings. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [controlled_egress](variables.tf#L26) | Controlled egress configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [custom_domain](variables.tf#L36) | Looker core instance custom domain. | <code>string</code> |  | <code>null</code> |
| [encryption_config](variables.tf#L42) | Set encryption configuration. KMS name format: 'projects/[PROJECT]/locations/[REGION]/keyRings/[RING]/cryptoKeys/[KEY_NAME]'. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [fips_enabled](variables.tf#L51) | FIPS 140-2 Encryption enablement for Looker (Google Cloud Core). | <code>bool</code> |  | <code>null</code> |
| [gemini_enabled](variables.tf#L57) | Gemini enablement for Looker (Google Cloud Core). | <code>bool</code> |  | <code>null</code> |
| [maintenance_config](variables.tf#L63) | Set maintenance window configuration and maintenance deny period (up to 90 days). Date format: 'yyyy-mm-dd'. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [periodic_export_config](variables.tf#L155) | Configuration for periodic export. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [platform_edition](variables.tf#L170) | Platform editions for a Looker instance. Each edition maps to a set of instance features, like its size. | <code>string</code> |  | <code>&#34;LOOKER_CORE_TRIAL&#34;</code> |
| [prefix](variables.tf#L180) | Optional prefix used to generate instance names. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [egress_public_ip](outputs.tf#L17) | Public IP address of Looker instance for egress. |  |
| [egress_service_attachments](outputs.tf#L22) | Egress service attachment connection statuses and configurations. |  |
| [id](outputs.tf#L27) | Fully qualified primary instance id. |  |
| [ingress_private_ip](outputs.tf#L32) | Private IP address of Looker instance for ingress. |  |
| [ingress_public_ip](outputs.tf#L37) | Public IP address of Looker instance for ingress. |  |
| [instance](outputs.tf#L42) | Looker Core instance resource. | ✓ |
| [instance_id](outputs.tf#L48) | Looker Core instance id. | ✓ |
| [instance_name](outputs.tf#L54) | Name of the looker instance. |  |
| [looker_service_attachment](outputs.tf#L59) | Service attachment URI for the Looker instance. |  |
| [looker_uri](outputs.tf#L64) | Looker core URI. |  |
| [looker_version](outputs.tf#L69) | Looker core version. |  |
<!-- END TFDOC -->
